import uuid

from fastapi import APIRouter, UploadFile

from app.core.storage import presigned_get_url, upload_bytes
from app.models.schemas import PresignedUrl

router = APIRouter(prefix="/api/v1/assets", tags=["assets"])


@router.post("/upload", response_model=PresignedUrl)
async def upload_asset(file: UploadFile):
    key = f"uploads/{uuid.uuid4()}-{file.filename}"
    data = await file.read()
    upload_bytes(key, data, content_type=file.content_type or "application/octet-stream")
    return PresignedUrl(key=key, url=presigned_get_url(key), expires_in=3600)


@router.get("/{key:path}/download", response_model=PresignedUrl)
def get_download_url(key: str):
    return PresignedUrl(key=key, url=presigned_get_url(key), expires_in=3600)
