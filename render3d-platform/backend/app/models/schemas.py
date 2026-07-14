from datetime import datetime
from enum import Enum
from typing import Any, Optional
from uuid import UUID, uuid4

from pydantic import BaseModel, Field


class JobStatus(str, Enum):
    queued = "queued"
    running = "running"
    succeeded = "succeeded"
    failed = "failed"


class JobKind(str, Enum):
    mesh_process = "mesh_process"
    blender_render = "blender_render"
    text_to_3d = "text_to_3d"


class RenderJobCreate(BaseModel):
    kind: JobKind = JobKind.mesh_process
    source_asset_key: str = Field(..., description="S3 object key of the input asset")
    target_format: str = Field("glb", description="glb | gltf | usd")
    draco_compress: bool = True
    simplify_ratio: float = Field(1.0, ge=0.05, le=1.0, description="1.0 = no simplification")
    params: dict[str, Any] = Field(default_factory=dict)


class RenderJob(BaseModel):
    id: UUID = Field(default_factory=uuid4)
    kind: JobKind
    status: JobStatus = JobStatus.queued
    source_asset_key: str
    prompt: Optional[str] = None
    result_asset_key: Optional[str] = None
    error: Optional[str] = None
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)


class PresignedUrl(BaseModel):
    key: str
    url: str
    expires_in: int


class TextTo3DRequest(BaseModel):
    prompt: str = Field(..., min_length=3, max_length=1000, description='e.g. "anime character, full body, T-pose"')
    style: str = Field("anime", description="anime | realistic | stylized | low-poly")
    target_format: str = Field("glb", description="glb | gltf")
