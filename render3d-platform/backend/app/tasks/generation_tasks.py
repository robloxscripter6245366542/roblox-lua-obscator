"""Text-to-3D generation via a pluggable provider — either a generic vendor
HTTP API, or local GPU inference with microsoft/TRELLIS.

TEXT23D_PROVIDER=http (default): point TEXT23D_API_URL at whichever
text-to-3D API you have a contract with (e.g. Meshy, Tripo3D, CSM.ai) and
set TEXT23D_API_KEY to your key. The provider is expected to expose a
job-style REST contract:

    POST {TEXT23D_API_URL}/generations  {"prompt": ..., "style": ...}
        -> {"id": "<task-id>"}
    GET  {TEXT23D_API_URL}/generations/{id}
        -> {"status": "pending|running|succeeded|failed", "asset_url": "..."}

Adjust `_start_generation` / `_poll_generation` if your provider's contract
differs.

TEXT23D_PROVIDER=trellis: runs microsoft/TRELLIS locally on this worker's
GPU instead of calling out to a vendor. See app/tasks/providers/trellis_provider.py
and docs/trellis-setup.md.
"""
import logging
import time

import requests

from app.core.celery_app import celery_app
from app.core.config import get_settings
from app.core.db import SessionLocal
from app.core.repository import update_job_status
from app.core.storage import upload_bytes

log = logging.getLogger(__name__)


class ProviderNotConfigured(RuntimeError):
    pass


def _headers(api_key: str) -> dict:
    return {"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"}


def _start_generation(api_url: str, api_key: str, prompt: str, style: str) -> str:
    resp = requests.post(
        f"{api_url.rstrip('/')}/generations",
        headers=_headers(api_key),
        json={"prompt": prompt, "style": style},
        timeout=30,
    )
    resp.raise_for_status()
    return resp.json()["id"]


def _poll_generation(api_url: str, api_key: str, task_id: str, interval: int, timeout: int = 900) -> str:
    deadline = time.time() + timeout
    while time.time() < deadline:
        resp = requests.get(
            f"{api_url.rstrip('/')}/generations/{task_id}",
            headers=_headers(api_key),
            timeout=30,
        )
        resp.raise_for_status()
        data = resp.json()
        if data["status"] == "succeeded":
            return data["asset_url"]
        if data["status"] == "failed":
            raise RuntimeError(f"generation provider reported failure: {data.get('error', 'unknown')}")
        time.sleep(interval)
    raise TimeoutError(f"text-to-3d generation timed out after {timeout}s")


def _generate_via_trellis(prompt: str) -> bytes:
    from app.tasks.providers.trellis_provider import generate_glb

    return generate_glb(prompt)


def _generate_via_http(settings, prompt: str, style: str) -> bytes:
    if not settings.text23d_api_url or not settings.text23d_api_key:
        raise ProviderNotConfigured(
            "Set TEXT23D_API_URL and TEXT23D_API_KEY to a real text-to-3D "
            "provider (e.g. Meshy, Tripo3D, CSM.ai), or set "
            "TEXT23D_PROVIDER=trellis to run microsoft/TRELLIS locally on "
            "a GPU worker (see docs/trellis-setup.md)."
        )
    task_id = _start_generation(settings.text23d_api_url, settings.text23d_api_key, prompt, style)
    asset_url = _poll_generation(
        settings.text23d_api_url, settings.text23d_api_key, task_id, settings.text23d_poll_interval_seconds
    )
    return requests.get(asset_url, timeout=120).content


@celery_app.task(name="render3d.generate_text_to_3d", bind=True, max_retries=1)
def generate_text_to_3d(self, job_id: str, prompt: str, style: str, target_format: str):
    settings = get_settings()
    db = SessionLocal()
    try:
        update_job_status(db, job_id, status="running")

        if settings.text23d_provider == "trellis":
            asset_bytes = _generate_via_trellis(prompt)
        else:
            asset_bytes = _generate_via_http(settings, prompt, style)

        result_key = f"generated/{job_id}/character.{target_format}"
        upload_bytes(result_key, asset_bytes, content_type="model/gltf-binary")

        update_job_status(db, job_id, status="succeeded", result_asset_key=result_key)
        return {"job_id": job_id, "result_asset_key": result_key}
    except Exception as exc:
        log.exception("text-to-3d generation failed for job %s", job_id)
        update_job_status(db, job_id, status="failed", error=str(exc))
        raise
    finally:
        db.close()

