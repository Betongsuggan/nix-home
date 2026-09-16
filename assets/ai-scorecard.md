# AI Lab Scorecard

Running list of models tried on `desktop` (RX 9070 XT 16 GB · gfx1201 · ROCm 7.2). Numbers come from real use, not synthetic benchmarks — fill `Speed` from `ollama run … --verbose` or wall-clock for image/voice. `Verdict`: **keep** (default-on in Nix), **test** (currently evaluating), **drop** (uninstall + remove from `ai-server.models`).

Update this file as you try things; it's the source of truth for which models earn a permanent slot.

## Chat / instruct (Ollama)

| Model | Size (Q4) | Speed | VRAM | Notes | Verdict |
|---|---|---|---|---|---|
| `qwen3:8b`             | ~5 GB | ? tok/s | ? | Fast lane, always-loaded candidate. | test |
| `qwen3:14b`            | ~9 GB | — | — | Best all-round dense at this tier; thinking mode. | candidate |
| `gpt-oss:20b`          | ~12 GB | — | — | MoE; reported ~90 tok/s on this exact card. | candidate |
| `gemma3:12b`           | ~8 GB | — | — | Strong writing tone, vision/image input. | candidate |

## Coding (Ollama)

| Model | Size (Q4) | Speed | VRAM | Notes | Verdict |
|---|---|---|---|---|---|
| `qwen2.5-coder:14b`    | ~9 GB | ? tok/s | ? | aider chat/edit. Smoke-tested. | test |
| `qwen2.5-coder:1.5b`   | ~1 GB | ? tok/s | ? | Tab-autocomplete (low latency). | test |

## Image generation (ComfyUI)

| Model | Size | Speed (1024² SDXL-class) | VRAM | Notes | Verdict |
|---|---|---|---|---|---|
| `sd_xl_base_1.0`       | ~7 GB | ? s | ? | Reference baseline; widest community support. | test |
| `sd_xl_turbo_1.0_fp16` | ~7 GB | ? s | ? | 1-4 step fast variant. Lower quality. | test |
| SD 3.5 Medium          | ~5 GB | — | — | Newer arch, better text rendering. Needs HF login. | candidate |
| Flux.1-schnell (Q4 GGUF) | ~6-8 GB | — | — | 4-step Flux. Frontier-ish quality. | candidate |
| Flux.1-dev (Q4 GGUF)   | ~6-7 GB | — | — | Frontier quality, slower (20-30 step). Non-commercial license. | candidate |

## Voice (Speaches)

| Model | Role | Size | Speed | Notes | Verdict |
|---|---|---|---|---|---|
| `deepdml/faster-whisper-large-v3-turbo-ct2` | STT | ~1.5 GB | ? s/clip | CPU-only; default for Open WebUI Audio. | test |
| `speaches-ai/Kokoro-82M-v1.0-ONNX-fp16`     | TTS | ~300 MB | ? s/sentence | Voice `af_heart`. Decent quality, fast. | test |

## Steady-state roster (goal)

Once evaluation settles, this is the lean set declared in `ai-server.models` + `voice.*Model` + the ComfyUI default. Aim for one daily chat + one autocomplete + one image baseline + one STT + one TTS.

| Slot | Current pick |
|---|---|
| Daily chat | — *(decide after comparing 8b/14b/20b)* |
| Code chat / edit | qwen2.5-coder:14b |
| Code autocomplete | qwen2.5-coder:1.5b |
| Image baseline | sd_xl_base_1.0 |
| STT | deepdml/faster-whisper-large-v3-turbo-ct2 |
| TTS | speaches-ai/Kokoro-82M (af_heart) |

## How to fill in numbers

```bash
# tok/s for an Ollama model (eval rate is the row that matters)
ollama run <model> --verbose "Explain NixOS modules in three paragraphs." 2>&1 | tail -10

# 1024² SDXL wall-clock — visible in ComfyUI logs or the UI
sudo docker logs comfyui --since 2m 2>&1 | grep "Prompt executed"

# VRAM while a model is loaded
nix run nixpkgs#amdgpu_top -- -d
```
