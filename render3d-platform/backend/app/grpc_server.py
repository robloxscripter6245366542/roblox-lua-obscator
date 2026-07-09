"""Standalone gRPC server exposing RenderService for internal
service-to-service calls (e.g. a scheduler handing work directly to a GPU
worker pool, bypassing the HTTP API / Celery queue for low-latency paths)."""

import logging
import time
from concurrent import futures

import grpc

from app.core.celery_app import celery_app
from app.core.config import get_settings
from app.core.db import SessionLocal
from app.core.repository import create_job, get_job
from app.grpc_gen import renderer_pb2, renderer_pb2_grpc
from app.models.schemas import JobKind, RenderJobCreate
from app.tasks.render_tasks import process_mesh

log = logging.getLogger(__name__)


class RenderServiceServicer(renderer_pb2_grpc.RenderServiceServicer):
    def SubmitRender(self, request, context):
        db = SessionLocal()
        try:
            record = create_job(
                db,
                RenderJobCreate(
                    kind=JobKind.mesh_process,
                    source_asset_key=request.source_asset_key,
                    target_format=request.target_format or "glb",
                    draco_compress=request.draco_compress,
                    simplify_ratio=request.simplify_ratio or 1.0,
                ),
            )
            process_mesh.delay(
                job_id=record.id,
                source_asset_key=record.source_asset_key,
                target_format=request.target_format or "glb",
                draco_compress=request.draco_compress,
                simplify_ratio=request.simplify_ratio or 1.0,
            )
            return renderer_pb2.RenderResponse(job_id=record.id, status=record.status)
        finally:
            db.close()

    def StreamStatus(self, request, context):
        db = SessionLocal()
        try:
            last_status = None
            while True:
                job = get_job(db, request.job_id)
                if job is None:
                    context.abort(grpc.StatusCode.NOT_FOUND, "job not found")
                    return
                if job.status != last_status:
                    last_status = job.status
                    yield renderer_pb2.StatusUpdate(
                        job_id=job.id,
                        status=job.status,
                        progress=1.0 if job.status == "succeeded" else 0.0,
                        message=job.error or "",
                    )
                if job.status in ("succeeded", "failed"):
                    return
                time.sleep(1)
        finally:
            db.close()


def serve() -> None:
    settings = get_settings()
    server = grpc.server(futures.ThreadPoolExecutor(max_workers=10))
    renderer_pb2_grpc.add_RenderServiceServicer_to_server(RenderServiceServicer(), server)
    server.add_insecure_port(f"[::]:{settings.grpc_port}")
    server.start()
    log.info("gRPC RenderService listening on port %s", settings.grpc_port)
    server.wait_for_termination()


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    serve()
