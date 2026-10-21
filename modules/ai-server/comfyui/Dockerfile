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

# Pinned by digest: `latest` was swapped for a differently laid-out image
# (rocm-ai-docker-stack, no git, no `python` alias) in Oct 2026 and broke
# the service. Bump: `nix run nixpkgs#crane -- digest rocm/pytorch:latest`,
# paste the new digest, rebuild, and watch the first start.
FROM rocm/pytorch:latest@sha256:099f59a3bee9c436f5cc57db6bc6076fdeda579c57e9e22ae40f856d5905b3e4

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

# A pinned ComfyUI release, fetched by Docker itself: the base image stopped
# shipping git (Oct 2026), and a tag beats an unpinned clone of master.
# Bump: change the tag; a Dockerfile edit changes the build context, so the
# next `nixos-rebuild switch` rebuilds the image.
ARG COMFYUI_VERSION=v0.42.3
ADD https://github.com/comfyanonymous/ComfyUI/archive/refs/tags/${COMFYUI_VERSION}.tar.gz /tmp/comfyui.tar.gz
RUN mkdir -p /opt/ComfyUI \
 && tar -xzf /tmp/comfyui.tar.gz -C /opt/ComfyUI --strip-components=1 \
 && rm /tmp/comfyui.tar.gz

# The image ships python3 only; the unit starts `python`.
RUN command -v python > /dev/null || ln -s "$(command -v python3)" /usr/local/bin/python

WORKDIR /opt/ComfyUI
# Strip torch/torchvision/torchaudio from requirements so pip doesn't
# overwrite the base image's ROCm-built PyTorch with a CPU-only PyPI wheel.
RUN sed -i -E '/^(torch|torchvision|torchaudio)([[:space:]]|=|<|>|$)/d' requirements.txt \
 && pip install -r requirements.txt

EXPOSE 8188

# Bind 0.0.0.0 so a port-published container is reachable from the host.
CMD ["python", "main.py", "--listen", "0.0.0.0", "--port", "8188"]
