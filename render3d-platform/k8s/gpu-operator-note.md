# NVIDIA GPU Operator

The GPU worker deployment (`gpu-worker-deployment.yaml`) assumes the cluster
already has the [NVIDIA GPU Operator](https://github.com/NVIDIA/gpu-operator)
installed, which handles driver installation, the device plugin, DCGM
monitoring, and node labeling:

```
helm repo add nvidia https://helm.ngc.nvidia.com/nvidia
helm install gpu-operator nvidia/gpu-operator -n gpu-operator --create-namespace
```

Once installed, nodes with GPUs are labeled `nvidia.com/gpu.present=true` and
expose an `nvidia.com/gpu` resource that pods request in their `limits`.
