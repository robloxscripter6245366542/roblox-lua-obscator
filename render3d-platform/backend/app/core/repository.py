from sqlalchemy.orm import Session

from app.models.db_models import JobRecord
from app.models.schemas import RenderJobCreate


def create_job(db: Session, payload: RenderJobCreate) -> JobRecord:
    job = JobRecord(
        kind=payload.kind.value,
        source_asset_key=payload.source_asset_key,
        status="queued",
    )
    db.add(job)
    db.commit()
    db.refresh(job)
    return job


def create_generation_job(db: Session, kind: str, prompt: str) -> JobRecord:
    job = JobRecord(kind=kind, source_asset_key="", prompt=prompt, status="queued")
    db.add(job)
    db.commit()
    db.refresh(job)
    return job


def get_job(db: Session, job_id: str) -> JobRecord | None:
    return db.get(JobRecord, job_id)


def update_job_status(
    db: Session,
    job_id: str,
    status: str,
    result_asset_key: str | None = None,
    error: str | None = None,
) -> JobRecord | None:
    job = db.get(JobRecord, job_id)
    if job is None:
        return None
    job.status = status
    if result_asset_key is not None:
        job.result_asset_key = result_asset_key
    if error is not None:
        job.error = error
    db.commit()
    db.refresh(job)
    return job
