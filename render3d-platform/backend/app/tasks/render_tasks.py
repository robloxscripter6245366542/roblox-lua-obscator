import io
import logging
import tempfile
from pathlib import Path

import trimesh

from app.core.celery_app import celery_app
from app.core.db import SessionLocal
from app.core.repository import update_job_status
from app.core.storage import download_bytes, upload_bytes

log = logging.getLogger(__name__)


def _decimate(mesh: trimesh.Trimesh, ratio: float) -> trimesh.Trimesh:
    """Reduce triangle count. Requires the optional `fast-simplification`
    package; falls back to the original mesh if it isn't installed."""
    if ratio >= 1.0 or not hasattr(mesh, "simplify_quadric_decimation"):
        return mesh
    target_faces = max(4, int(len(mesh.faces) * ratio))
    try:
        return mesh.simplify_quadric_decimation(face_count=target_faces)
    except Exception as exc:  # optional dependency missing, or degenerate mesh
        log.warning("mesh decimation skipped: %s", exc)
        return mesh


def _draco_compress(glb_path: Path) -> Path | None:
    """Best-effort Draco compression of a GLB's geometry buffers.
    Returns None (and logs) when the optional `DracoPy` dependency is absent."""
    try:
        import DracoPy  # noqa: F401
    except ImportError:
        log.info("DracoPy not installed; shipping uncompressed glTF/GLB buffers")
        return None

    mesh = trimesh.load(glb_path, force="mesh")
    encoded = DracoPy.encode(mesh.vertices, mesh.faces)
    drc_path = glb_path.with_suffix(".drc")
    drc_path.write_bytes(encoded)
    return drc_path


@celery_app.task(name="render3d.process_mesh", bind=True, max_retries=2)
def process_mesh(self, job_id: str, source_asset_key: str, target_format: str, draco_compress: bool, simplify_ratio: float):
    db = SessionLocal()
    try:
        update_job_status(db, job_id, status="running")

        raw = download_bytes(source_asset_key)
        suffix = Path(source_asset_key).suffix or ".obj"

        with tempfile.TemporaryDirectory() as tmp:
            src_path = Path(tmp) / f"input{suffix}"
            src_path.write_bytes(raw)

            mesh = trimesh.load(src_path, force="mesh")
            mesh = _decimate(mesh, simplify_ratio)

            export_ext = "glb" if target_format not in ("gltf", "glb") else target_format
            out_path = Path(tmp) / f"output.{export_ext}"
            mesh.export(out_path)

            result_key = f"renders/{job_id}/output.{export_ext}"
            upload_bytes(result_key, out_path.read_bytes(), content_type="model/gltf-binary")

            if draco_compress:
                drc_path = _draco_compress(out_path)
                if drc_path is not None:
                    upload_bytes(f"renders/{job_id}/output.drc", drc_path.read_bytes())

        update_job_status(db, job_id, status="succeeded", result_asset_key=result_key)
        return {"job_id": job_id, "result_asset_key": result_key}
    except Exception as exc:
        log.exception("mesh processing failed for job %s", job_id)
        update_job_status(db, job_id, status="failed", error=str(exc))
        raise
    finally:
        db.close()


@celery_app.task(name="render3d.blender_render")
def blender_render(job_id: str, scene_asset_key: str, script: str = "render.py"):
    """Shells out to Blender's CLI for headless Cycles/Eevee rendering.
    Requires a `blender` binary on the worker image (see backend/Dockerfile.worker)."""
    import subprocess

    db = SessionLocal()
    try:
        update_job_status(db, job_id, status="running")
        raw = download_bytes(scene_asset_key)

        with tempfile.TemporaryDirectory() as tmp:
            scene_path = Path(tmp) / "scene.blend"
            scene_path.write_bytes(raw)
            out_path = Path(tmp) / "render.png"

            result = subprocess.run(
                ["blender", "-b", str(scene_path), "-o", str(out_path), "-f", "1"],
                capture_output=True,
                text=True,
                timeout=600,
            )
            if result.returncode != 0:
                raise RuntimeError(f"blender render failed: {result.stderr[-2000:]}")

            result_key = f"renders/{job_id}/frame.png"
            upload_bytes(result_key, out_path.read_bytes(), content_type="image/png")

        update_job_status(db, job_id, status="succeeded", result_asset_key=result_key)
        return {"job_id": job_id, "result_asset_key": result_key}
    except Exception as exc:
        log.exception("blender render failed for job %s", job_id)
        update_job_status(db, job_id, status="failed", error=str(exc))
        raise
    finally:
        db.close()
