import io
from functools import lru_cache

import boto3
from botocore.client import Config as BotoConfig
from botocore.exceptions import ClientError

from app.core.config import get_settings


@lru_cache
def get_s3_client():
    settings = get_settings()
    return boto3.client(
        "s3",
        endpoint_url=settings.s3_endpoint_url or None,
        aws_access_key_id=settings.s3_access_key,
        aws_secret_access_key=settings.s3_secret_key,
        region_name=settings.s3_region,
        config=BotoConfig(signature_version="s3v4"),
    )


def ensure_bucket() -> None:
    settings = get_settings()
    client = get_s3_client()
    try:
        client.head_bucket(Bucket=settings.s3_bucket)
    except ClientError:
        client.create_bucket(Bucket=settings.s3_bucket)


def upload_bytes(key: str, data: bytes, content_type: str = "application/octet-stream") -> str:
    settings = get_settings()
    ensure_bucket()
    get_s3_client().upload_fileobj(
        io.BytesIO(data), settings.s3_bucket, key, ExtraArgs={"ContentType": content_type}
    )
    return key


def download_bytes(key: str) -> bytes:
    settings = get_settings()
    buf = io.BytesIO()
    get_s3_client().download_fileobj(settings.s3_bucket, key, buf)
    return buf.getvalue()


def presigned_get_url(key: str, expires_in: int = 3600) -> str:
    settings = get_settings()
    return get_s3_client().generate_presigned_url(
        "get_object",
        Params={"Bucket": settings.s3_bucket, "Key": key},
        ExpiresIn=expires_in,
    )
