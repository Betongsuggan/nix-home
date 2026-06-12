# ComfyUI on AMD ROCm, built fresh against a modern ROCm + PyTorch.
#
# Why a custom Dockerfile rather than a community image:
#   - RDNA4 (gfx1201) on the RX 9070 XT needs ROCm 6.4+ / 7.x. Most community
#     ComfyUI-ROCm images at the time of writing are pinned to ROCm 6.0,
#     which lacks gfx1201 codegen and either fails to init the GPU or
#     segfaults under an HSA_OVERRIDE.
#   - `rocm/pytorch:latest` is the official AMD reference, kept current.
#
# Build:
#   docker build -t comfyui-rocm:local .
# Run (rootless docker on the host with /dev/kfd + /dev/dri passthrough):
#   docker run --rm -it \
#     --device=/dev/kfd --device=/dev/dri \
#     --group-add=<video-gid> --group-add=<render-gid> \
#     --security-opt=seccomp=unconfined \
#     -p 8188:8188 \
#     comfyui-rocm:local

FROM rocm/pytorch:latest

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

# git is present in the base image; keep this minimal so layer churn stays low.

WORKDIR /opt
RUN git clone --depth 1 https://github.com/comfyanonymous/ComfyUI.git

WORKDIR /opt/ComfyUI
# Strip torch/torchvision/torchaudio from requirements so pip doesn't
# overwrite the base image's ROCm-built PyTorch with a CPU-only PyPI wheel.
RUN sed -i -E '/^(torch|torchvision|torchaudio)([[:space:]]|=|<|>|$)/d' requirements.txt \
 && pip install -r requirements.txt

EXPOSE 8188

# Bind 0.0.0.0 so a port-published container is reachable from the host.
CMD ["python", "main.py", "--listen", "0.0.0.0", "--port", "8188"]
