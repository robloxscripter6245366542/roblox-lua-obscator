from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.db import get_db
from app.core.repository import create_generation_job
from app.models.schemas import RenderJob, TextTo3DRequest
from app.tasks.generation_tasks import generate_text_to_3d

router = APIRouter(prefix="/api/v1/generate", tags=["generate"])


@router.post("/text-to-3d", response_model=RenderJob, status_code=201)
def submit_text_to_3d(payload: TextTo3DRequest, db: Session = Depends(get_db)):
    record = create_generation_job(db, kind="text_to_3d", prompt=payload.prompt)

    generate_text_to_3d.delay(
        job_id=record.id,
        prompt=payload.prompt,
        style=payload.style,
        target_format=payload.target_format,
    )

    db.expire(record)
    db.refresh(record)
    return RenderJob(
        id=record.id,
        kind=record.kind,
        status=record.status,
        source_asset_key=record.source_asset_key,
        prompt=record.prompt,
        result_asset_key=record.result_asset_key,
        error=record.error,
        created_at=record.created_at,
        updated_at=record.updated_at,
    )
