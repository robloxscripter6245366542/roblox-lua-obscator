"""Local GPU inference via Microsoft's TRELLIS (image-to-3D / text-to-3D).

https://github.com/microsoft/TRELLIS — MIT licensed, but NOT a pip package:
it must be installed on the GPU worker node from source, since it ships
custom CUDA extensions (diffoctreerast, mip-splatting) and depends on
spconv / kaolin / nvdiffrast / flash-attn. See
`render3d-platform/k8s/gpu-worker-deployment.yaml` +
`docs/trellis-setup.md` for the one-time node setup.

This module is only imported lazily (inside the function below) so the API
and CPU-only workers never need `torch`/`trellis` installed — only the GPU
worker pods that opt into TEXT23D_PROVIDER=trellis do.
"""
import io
import logging

log = logging.getLogger(__name__)

_pipeline = None


def _get_pipeline():
    """Loads and caches the TRELLIS pipeline in this worker process.
    Requires ~16GB+ VRAM; loading takes tens of seconds on first call."""
    global _pipeline
    if _pipeline is not None:
        return _pipeline

    try:
        from trellis.pipelines import TrellisTextTo3DPipeline
    except ImportError as exc:
        raise RuntimeError(
            "TRELLIS is not installed on this worker. Follow "
            "render3d-platform/docs/trellis-setup.md to install it on a "
            "GPU node, or set TEXT23D_PROVIDER=http to use an external "
            "vendor API instead."
        ) from exc

    _pipeline = TrellisTextTo3DPipeline.from_pretrained("microsoft/TRELLIS-text-large")
    _pipeline.cuda()
    return _pipeline


def generate_glb(prompt: str, seed: int = 1) -> bytes:
    """Runs TRELLIS text-to-3D end to end and returns GLB bytes.

    Mirrors the pipeline shape from TRELLIS's own README: `.run()` returns a
    dict of representations (gaussians / radiance field / mesh); we export
    the mesh representation to glTF/GLB via trimesh for consistency with
    the rest of this platform's mesh_process pipeline.
    """
    import trimesh

    pipeline = _get_pipeline()
    outputs = pipeline.run(prompt, seed=seed)

    mesh = outputs["mesh"][0]
    trimesh_mesh = trimesh.Trimesh(vertices=mesh.vertices.cpu().numpy(), faces=mesh.faces.cpu().numpy())

    buf = io.BytesIO()
    trimesh_mesh.export(buf, file_type="glb")
    return buf.getvalue()
