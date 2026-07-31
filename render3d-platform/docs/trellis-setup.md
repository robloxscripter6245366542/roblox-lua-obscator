# Running microsoft/TRELLIS as a generation provider

[TRELLIS](https://github.com/microsoft/TRELLIS) (MIT licensed) is a
research-grade text/image-to-3D model. It is **not vendored into this repo**
— it ships custom CUDA extensions and multi-GB model weights that don't
belong in application source control, and it only runs on a Linux GPU node
with 16GB+ VRAM (tested on A100/A6000). Install it directly on the GPU
worker node instead:

```bash
git clone --recurse-submodules https://github.com/microsoft/TRELLIS.git
cd TRELLIS
. ./setup.sh --new-env --basic --xformers --flash-attn --diffoctreerast \
  --spconv --mip-splatting --kaolin --nvdiffrast
```

See the upstream README for CUDA version requirements (11.8 or 12.2) and
troubleshooting the extension builds — those steps change over time and are
best followed from the source rather than duplicated here.

## Wiring it into this platform

Once TRELLIS is importable in the worker's Python environment:

1. Set `TEXT23D_PROVIDER=trellis` on the Celery worker (not the API — the
   API never imports `trellis`/`torch`, only the worker does, lazily).
2. Deploy that worker on a GPU node (`k8s/gpu-worker-deployment.yaml` already
   requests `nvidia.com/gpu: 1` and tolerates the GPU Operator's taint).
3. `POST /api/v1/generate/text-to-3d` will now run inference locally via
   `app/tasks/providers/trellis_provider.py` instead of calling an external
   vendor API — no `TEXT23D_API_URL`/`TEXT23D_API_KEY` needed in this mode.

`trellis_provider.py` calls `TrellisTextTo3DPipeline.from_pretrained(...)`
per TRELLIS's own documented API and exports the resulting mesh to glTF/GLB
via trimesh, so it drops into the same job/storage pipeline as the
Blender/Open3D mesh-processing path.
