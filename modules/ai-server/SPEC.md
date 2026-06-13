# AI Server

Local AI inference for the tailnet. Runs:

- **Ollama** — OpenAI-compatible LLM API on AMD ROCm.
- **Open WebUI** — browser-based chat front-end wired to local Ollama.
- **ComfyUI** (optional) — image generation, in a custom ROCm container built on `rocm/pytorch:latest` so it actually works on RDNA4 (gfx1201).
- **Speaches** (optional) — OpenAI-API-compatible STT + TTS in a CPU container; consumed by Open WebUI's Audio settings.

All ports are bound on `tailscale0` only; clients reach them through controller's HTTPS reverse-proxy → wake-proxy chain (`modules/reverse-proxy/SPEC.md`, `modules/wake-proxy/SPEC.md`), so the host can sleep when idle. The canonical entry points are:

| URL | Service |
|---|---|
| `https://chat.rydback.net`   | Open WebUI |
| `https://llm.rydback.net`    | Ollama API |
| `https://images.rydback.net` | ComfyUI |
| `https://voice.rydback.net`  | Speaches (STT + TTS) |

Each is a tailnet-only nginx vhost on controller (`allow 100.64.0.0/10; deny all;`) with an ACME Let's Encrypt cert. The same hostnames have a public A record for the ACME challenge but a MagicDNS override pointing to controller's tailnet IP, so tailnet members reach the vhost from a 100.x source and pass the allow rule.

## Usage

```nix
ai-server = {
  enable = true;
  comfyui.enable = true;   # optional, off by default
};
```

## Options

| Option              | Type | Default | Description |
|---------------------|------|---------|-------------|
| enable              | bool | false  | Enable Ollama + Open WebUI |
| ollamaPort          | port | 11434  | Ollama HTTP API port; opened on `tailscale0` only |
| webuiPort           | port | 8081   | Open WebUI port; opened on `tailscale0` only (8080 is already used elsewhere) |
| models              | list of string | `[ ]` | Models to keep present on the host; pulled in the background after Ollama starts. Not destructive — removing an entry doesn't delete the model. |
| comfyui.enable      | bool | false  | Enable the ComfyUI container service |
| comfyui.port        | port | 8188   | ComfyUI HTTP port; opened on `tailscale0` only |
| comfyui.dataDir     | path | `/var/lib/comfyui` | Persistent state dir: `models/`, `output/`, `input/`, `user/`. Survives container restarts and image rebuilds. |
| voice.enable        | bool | false  | Enable the Speaches container (STT + TTS) |
| voice.port          | port | 8000   | Speaches HTTP port; opened on `tailscale0` only |
| voice.dataDir       | path | `/var/lib/speaches` | Persistent model cache (Hugging Face downloads) |
| voice.image         | string | `ghcr.io/speaches-ai/speaches:latest-cpu` | Container image. CPU is the safe default. |

## Notes

- Uses `pkgs.ollama-rocm`. If ROCm fails to init the GPU, swap to `pkgs.ollama-vulkan` in `default.nix` as a one-line fallback. The `graphics` module already enables the ROCm OpenCL ICD; this module adds `rocminfo` to the system path and the `/opt/rocm/hip` symlink some tooling expects.
- ComfyUI runs in a container built from `modules/ai-server/comfyui/Dockerfile` (thin layer on `rocm/pytorch:latest`). The build is run by a systemd `ExecStartPre` and is layer-cached; first launch will pull the ~15-20 GB base image — be patient. Edits to the Dockerfile are picked up by `nixos-rebuild switch` because the build context path changes. To download a model, drop the file into `${dataDir}/models/checkpoints/` (e.g. SDXL from Hugging Face).
- Speaches runs an upstream image (no custom Dockerfile). Models download on first use into `voice.dataDir` and are reused thereafter. After the service is up, wire it into Open WebUI manually: **Admin → Settings → Audio**, set both STT and TTS to `OpenAI` with `Base URL = http://localhost:8000/v1` (same-host loopback — no HTTPS needed for that hop), any dummy API key, an STT model id from `GET /v1/registry`, and a TTS voice id from the registry.
- Mobile browsers require **HTTPS** for `getUserMedia`. Use `https://chat.rydback.net` from a phone — the reverse-proxy on controller terminates TLS with a Let's Encrypt cert. `tailscale serve --https` was rejected as an option because the self-hosted headscale control server returns 404 on the cert-issuance endpoint.
- Verified on AMD Radeon RX 9070 XT (`gfx1201`, RDNA4) with Ryzen 7 5700X3D and 16 GB RAM.
- `OLLAMA_KEEP_ALIVE=24h` keeps models warm; `OLLAMA_MAX_LOADED_MODELS=1` is required at 16 GB system RAM. Bump the cap if RAM is upgraded.
- Bound to `0.0.0.0` but firewalled to `tailscale0`. Direct LAN access is intentionally closed — everything routes through controller's wake-proxy.

## Verification

```bash
# On the host
systemctl status ollama open-webui
rocminfo | grep gfx                                     # → gfx1201
ollama pull qwen3:8b
ollama run qwen3:8b --verbose "Say hi" 2>&1 | tail -10  # eval rate 60-80 tok/s on RX 9070 XT

# ComfyUI (if enabled)
systemctl status comfyui
sudo docker logs comfyui 2>&1 | grep -E 'VRAM|gfx|Device:' | head

# From another tailnet host
curl https://llm.rydback.net/api/tags                   # Ollama API via HTTPS vhost
# In a browser: https://chat.rydback.net    (Open WebUI)
# In a browser: https://images.rydback.net  (ComfyUI)
# In a browser: https://voice.rydback.net   (Speaches Gradio UI)
```

Eval rate under ~10 tok/s means the model is on CPU — check `journalctl -u ollama` for ROCm init errors. First time Open WebUI is opened, register an admin account; subsequent users can register but admin approves them. ComfyUI's GPU detection should show `Device: cuda:0 AMD Radeon RX 9070 XT` and `AMD arch: gfx1201`.
