# render3d-platform

A GPU-accelerated 3D asset pipeline: FastAPI + gRPC API, Celery/GPU workers
for mesh processing (Open3D/Trimesh/Blender) and text-to-3D generation, and
a Three.js web preview.

## Layout

- `backend/` — FastAPI app, Celery tasks, gRPC service, Dockerfiles
- `k8s/` — Kubernetes manifests (API, GPU worker pool, gRPC service)
- `site/` — static showcase + live Three.js viewer + generation demo
- `docker-compose.yml` — Postgres, Redis, MinIO, API, worker, gRPC

## Quick start (local, no Docker)

```bash
cd backend
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```

Defaults to SQLite (`render3d.db`) so it runs with zero extra services.
Set `POSTGRES_DSN`, `REDIS_URL`, and `S3_*` env vars to point at real
infrastructure (see `docker-compose.yml` for the full set).

To run the Celery worker: `celery -A app.core.celery_app worker --loglevel=info`
(needs `REDIS_URL` pointing at a running Redis).

## Full stack via Docker Compose

```bash
docker compose up --build
```

Brings up Postgres, Redis, MinIO, the API (`:8000`), a Celery worker, and
the gRPC service (`:50051`).

## Text-to-3D generation

`POST /api/v1/generate/text-to-3d` hands a prompt to a pluggable provider,
selected via `TEXT23D_PROVIDER`:

- `http` (default) — a generic vendor REST API (Meshy, Tripo3D, CSM.ai, ...).
  Set `TEXT23D_API_URL` and `TEXT23D_API_KEY`; without them the job fails
  fast with an explanatory error instead of hanging.
- `trellis` — runs [microsoft/TRELLIS](https://github.com/microsoft/TRELLIS)
  locally on the worker's GPU instead of calling an external vendor. See
  `docs/trellis-setup.md` for installing it on a GPU worker node.

## Site

`site/` is a static, dependency-free (vendored Three.js) page. Serve it
with any static file server, e.g. `python3 -m http.server` from `site/`.
