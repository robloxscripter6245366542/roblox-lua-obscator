"""Manual smoke test (not part of CI): boots a mocked S3, runs Celery in
eager mode, submits a mesh_process job through the real FastAPI app, and
asserts the pipeline produces a downloadable GLB.

Run from backend/ with:
    pip install -r requirements.txt moto[s3] httpx
    PYTHONPATH=. python scripts/e2e_smoke.py
"""
import os
from pathlib import Path

os.environ["POSTGRES_DSN"] = "sqlite:///./e2e_test.db"
# moto only intercepts real AWS endpoints, not custom MinIO-style URLs,
# so point at the default AWS endpoint for this in-process smoke test.
os.environ["S3_ENDPOINT_URL"] = ""
os.environ["S3_REGION"] = "us-east-1"

from moto import mock_aws
from fastapi.testclient import TestClient

FIXTURE = Path(__file__).parent / "fixtures" / "sample_mesh.obj"

with mock_aws():
    from app.core.celery_app import celery_app

    celery_app.conf.task_always_eager = True
    celery_app.conf.task_eager_propagates = True

    from app.core.storage import upload_bytes
    from app.main import app

    with TestClient(app) as client:
        upload_bytes("uploads/sample_mesh.obj", FIXTURE.read_bytes(), content_type="model/obj")

        resp = client.post(
            "/api/v1/jobs",
            json={
                "kind": "mesh_process",
                "source_asset_key": "uploads/sample_mesh.obj",
                "target_format": "glb",
                "draco_compress": True,
                "simplify_ratio": 0.5,
            },
        )
        print("submit status:", resp.status_code, resp.json())
        job = resp.json()
        assert job["status"] == "succeeded", job

        status_resp = client.get(f"/api/v1/jobs/{job['id']}")
        print("status:", status_resp.json())
        assert status_resp.json()["result_asset_key"]

        print("E2E OK")
