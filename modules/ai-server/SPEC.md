# AI Server

Local AI inference for the tailnet. Hosts Ollama on AMD ROCm and exposes the OpenAI-compatible API on `tailscale0` only. Clients reach it through controller's wake-proxy (see `modules/wake-proxy/SPEC.md` once that lands), so the host is free to sleep when idle.

## Usage

```nix
ai-server.enable = true;
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Enable the AI server (Ollama only, for now) |
| port   | port | 11434  | Ollama HTTP API port; opened on `tailscale0` only |

## Notes

- Uses `pkgs.ollama-rocm`. If ROCm fails to init the GPU, swap to `pkgs.ollama-vulkan` in `default.nix` as a one-line fallback. The `graphics` module already enables the ROCm OpenCL ICD; this module adds `rocminfo` to the system path and the `/opt/rocm/hip` symlink some tooling expects.
- Verified on AMD Radeon RX 9070 XT (`gfx1201`, RDNA4) with Ryzen 7 5700X3D and 16 GB RAM.
- `OLLAMA_KEEP_ALIVE=24h` keeps models warm; `OLLAMA_MAX_LOADED_MODELS=1` is required at 16 GB system RAM. Bump the cap if RAM is upgraded.
- Bound to `0.0.0.0` but firewalled to `tailscale0`. Direct LAN access is intentionally closed — everything routes through controller's wake-proxy.

## Verification

```bash
# On the host
systemctl status ollama
rocminfo | grep gfx                                     # → gfx1201
ollama pull qwen3:8b
ollama run qwen3:8b --verbose "Say hi" 2>&1 | tail -10  # eval rate 60-80 tok/s on RX 9070 XT

# From another tailnet host
curl http://desktop:11434/api/tags
```

Eval rate under ~10 tok/s means the model is on CPU — check `journalctl -u ollama` for ROCm init errors.
