from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.db import get_db
from app.core.repository import create_job, get_job
from app.models.schemas import JobKind, RenderJob, RenderJobCreate
from app.tasks.render_tasks import blender_render, process_mesh

router = APIRouter(prefix="/api/v1/jobs", tags=["jobs"])


def _to_schema(record) -> RenderJob:
    return RenderJob(
        id=record.id,
        kind=record.kind,
        status=record.status,
        source_asset_key=record.source_asset_key,
        result_asset_key=record.result_asset_key,
        error=record.error,
        created_at=record.created_at,
        updated_at=record.updated_at,
    )


@router.post("", response_model=RenderJob, status_code=201)
def submit_job(payload: RenderJobCreate, db: Session = Depends(get_db)):
    record = create_job(db, payload)

    if payload.kind == JobKind.mesh_process:
        process_mesh.delay(
            job_id=record.id,
            source_asset_key=payload.source_asset_key,
            target_format=payload.target_format,
            draco_compress=payload.draco_compress,
            simplify_ratio=payload.simplify_ratio,
        )
    else:
        blender_render.delay(job_id=record.id, scene_asset_key=payload.source_asset_key)

    # Re-fetch: in Celery's eager test mode the task above has already run
    # (in a separate DB session) by the time .delay() returns.
    db.expire(record)
    return _to_schema(get_job(db, record.id))


@router.get("/{job_id}", response_model=RenderJob)
def get_job_status(job_id: UUID, db: Session = Depends(get_db)):
    record = get_job(db, str(job_id))
    if record is None:
        raise HTTPException(status_code=404, detail="job not found")
    return _to_schema(record)
