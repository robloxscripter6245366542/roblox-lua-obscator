import os
from functools import lru_cache

from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    app_name: str = "render3d-platform-api"
    environment: str = os.getenv("ENVIRONMENT", "development")

    # Empty by default so local dev falls back to SQLite (see app.core.db);
    # set to a postgresql:// URL in staging/production (see docker-compose.yml).
    postgres_dsn: str = os.getenv("POSTGRES_DSN", "")

    redis_url: str = os.getenv("REDIS_URL", "redis://localhost:6379/0")
    celery_broker_url: str = os.getenv("CELERY_BROKER_URL", os.getenv("REDIS_URL", "redis://localhost:6379/0"))
    celery_result_backend: str = os.getenv(
        "CELERY_RESULT_BACKEND", os.getenv("REDIS_URL", "redis://localhost:6379/0")
    )

    s3_endpoint_url: str = os.getenv("S3_ENDPOINT_URL", "http://localhost:9000")
    s3_access_key: str = os.getenv("S3_ACCESS_KEY", "minioadmin")
    s3_secret_key: str = os.getenv("S3_SECRET_KEY", "minioadmin")
    s3_bucket: str = os.getenv("S3_BUCKET", "render3d-assets")
    s3_region: str = os.getenv("S3_REGION", "us-east-1")

    grpc_port: int = int(os.getenv("GRPC_PORT", "50051"))

    # Pluggable text-to-3D generation provider.
    #   "http"    -> generic vendor REST API (Meshy, Tripo3D, CSM.ai, ...);
    #                set TEXT23D_API_URL / TEXT23D_API_KEY to your account.
    #   "trellis" -> local GPU inference via microsoft/TRELLIS on this worker
    #                node; see docs/trellis-setup.md. No API key needed, but
    #                the worker needs a 16GB+ VRAM GPU and TRELLIS installed.
    text23d_provider: str = os.getenv("TEXT23D_PROVIDER", "http")
    text23d_api_url: str = os.getenv("TEXT23D_API_URL", "")
    text23d_api_key: str = os.getenv("TEXT23D_API_KEY", "")
    text23d_poll_interval_seconds: int = int(os.getenv("TEXT23D_POLL_INTERVAL_SECONDS", "5"))

    class Config:
        env_file = ".env"


@lru_cache
def get_settings() -> Settings:
    return Settings()
