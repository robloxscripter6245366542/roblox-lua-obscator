from celery import Celery

from app.core.config import get_settings

settings = get_settings()

celery_app = Celery(
    "render3d",
    broker=settings.celery_broker_url,
    backend=settings.celery_result_backend,
    include=["app.tasks.render_tasks", "app.tasks.generation_tasks"],
)

celery_app.conf.update(
    task_serializer="json",
    accept_content=["json"],
    result_serializer="json",
    task_track_started=True,
    worker_prefetch_multiplier=1,
)
