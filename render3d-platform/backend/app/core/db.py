from sqlalchemy import create_engine
from sqlalchemy.orm import DeclarativeBase, Session, sessionmaker

from app.core.config import get_settings

settings = get_settings()

# Defaults to a local SQLite file so the API runs with zero extra services;
# set POSTGRES_DSN to a postgresql:// URL in staging/production.
_dsn = settings.postgres_dsn or "sqlite:///./render3d.db"
_connect_args = {"check_same_thread": False} if _dsn.startswith("sqlite") else {}

engine = create_engine(_dsn, connect_args=_connect_args)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


class Base(DeclarativeBase):
    pass


def get_db() -> Session:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def init_db() -> None:
    from app.models import db_models  # noqa: F401

    Base.metadata.create_all(bind=engine)
