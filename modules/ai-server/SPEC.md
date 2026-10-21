# AI Server

Local AI inference for the tailnet. Runs:

- **Ollama** — OpenAI-compatible LLM API on the Vulkan backend (`pkgs.ollama-vulkan`).
- **Open WebUI** — browser-based chat front-end wired to local Ollama.
- **ComfyUI** (optional) — image generation, in a custom ROCm container built on `rocm/pytorch:latest` so it actually works on RDNA4 (gfx1201).
- **Speaches** (optional) — OpenAI-API-compatible STT + TTS in a CPU container; consumed by Open WebUI's Audio settings.
- **SearXNG** (optional, `search.enable`) — self-hosted metasearch backend so chats can fetch live web content. Loopback-only.
- **Tika** (optional, `documents.enable`) — Apache Tika sidecar so Open WebUI's Knowledge feature parses uploaded PDFs/Office docs into clean text. Loopback-only.
- **Jupyter** (optional, `codeInterpreter.enable`) — sandboxed Python kernel so the LLM can run code via the code-interpreter tool. Loopback-only, token-authenticated.
- **RAG via local Ollama embeddings** — `nomic-embed-text` is auto-loaded; Open WebUI uses it for Knowledge embedding, memory recall, and web-search reranking. Hybrid BM25+vector search is enabled.
- **Memory** (`features.memory`) — Open WebUI's per-user long-term memory with all three of its mechanisms on: the memory bank, injection of stored memories into every chat's system context, and *background review* (every 10 turns the chat model re-reads the conversation and adds/updates memories by itself). Models can also write memories directly through tool calls, which needs **Function Calling: Native** on the model (see Setup). See the Memory section below.
- **Context compaction** — long chats are summarised instead of silently truncated: once a chat passes ~70 % of `contextLength` the model condenses the older turns and keeps the latest 40 % verbatim.
- **MCP / Direct Connections, message rating, evaluation arena, folders, notes** are on by default via `features.*` toggles.

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
my.ai-server = {
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
| contextLength       | int  | 16384  | Ollama context window in tokens for every model and client (`OLLAMA_CONTEXT_LENGTH`). Ollama's own default is 4096. Open WebUI's compaction threshold is 70 % of this. |
| taskModel           | null or string | null | Small non-thinking model for Open WebUI's side jobs (titles, tags, follow-ups, query generation; `TASK_MODEL`). Pulled with `models`; raises the loaded-model cap to 3. Without it those jobs queue on the chat model's single slot, and with a thinking model each of them thinks first, so a reply can take minutes to start. |
| models              | list of string | `[ ]` | Models to keep present on the host; pulled in the background after Ollama starts. Not destructive — removing an entry doesn't delete the model. |
| comfyui.enable      | bool | false  | Enable the ComfyUI container service |
| comfyui.port        | port | 8188   | ComfyUI HTTP port; opened on `tailscale0` only |
| comfyui.dataDir     | path | `/var/lib/comfyui` | Persistent state dir: `models/`, `output/`, `input/`, `user/`. Survives container restarts and image rebuilds. |
| voice.enable        | bool | false  | Enable the Speaches container (STT + TTS) |
| voice.port          | port | 8000   | Speaches HTTP port; opened on `tailscale0` only |
| voice.dataDir       | path | `/var/lib/speaches` | Persistent model cache (Hugging Face downloads) |
| voice.image         | string | `ghcr.io/speaches-ai/speaches:latest-cpu` | Container image. CPU is the safe default. |
| voice.sttModel      | string | `deepdml/faster-whisper-large-v3-turbo-ct2` | STT model id; pre-pulled on activation |
| voice.ttsModel      | string | `speaches-ai/Kokoro-82M-v1.0-ONNX-fp16` | TTS model id; pre-pulled on activation |
| voice.ttsVoice      | string | `af_heart` | Default voice id (see `/v1/audio/speech/voices`) |
| search.enable       | bool | false  | Enable the SearXNG container |
| search.port         | port | 8082   | SearXNG HTTP port (loopback-only) |
| search.image        | string | `searxng/searxng:latest` | Container image |
| search.dataDir      | path | `/var/lib/searxng` | Persistent cache dir |
| documents.enable    | bool | false  | Enable the Apache Tika container |
| documents.port      | port | 9998   | Tika HTTP port (loopback-only) |
| documents.image     | string | `apache/tika:latest` | Container image |
| codeInterpreter.enable | bool | false | Enable the Jupyter container |
| codeInterpreter.port   | port | 8888   | Jupyter HTTP port (loopback-only) |
| codeInterpreter.image  | string | `quay.io/jupyter/minimal-notebook:latest` | Container image |
| codeInterpreter.dataDir | path | `/var/lib/jupyter` | Notebook state |
| features.memory     | bool | true   | Open WebUI per-user memory: bank + system-context injection + background review every 10 turns |
| features.directConnections | bool | true | Enable MCP / OpenAPI tool-server connections |
| features.evaluationArena   | bool | true | Message rating + model comparison |

## Notes

- Uses `pkgs.ollama-vulkan`: on RDNA4 (gfx1201) llama.cpp's Vulkan backend generates tokens 10-20 % faster than HIP in community benchmarks and has no ROCm version coupling. `pkgs.ollama-rocm` is the one-line fallback in `nixos.nix` if Vulkan misbehaves (ComfyUI still runs on ROCm in its own container). The `graphics` module enables the ROCm OpenCL ICD; this module adds `rocminfo` to the system path and the `/opt/rocm/hip` symlink some tooling expects.
- Ollama runs with `OLLAMA_CONTEXT_LENGTH=<contextLength>` (default 16384; Ollama's own default is 4096, which a system prompt + memories + RAG chunks exhaust in a few turns, after which the oldest tokens are dropped silently), `OLLAMA_FLASH_ATTENTION=1` + `OLLAMA_KV_CACHE_TYPE=q8_0` (halves the KV-cache cost of that window), and `OLLAMA_MAX_LOADED_MODELS=2` so the chat model and `nomic-embed-text` stay loaded together. With a limit of one, every memory/RAG/web-search embedding call evicted the chat model and the reply reloaded it.

## Memory

Open WebUI (>= 0.10) has three ways memories move between chats; this module turns all of them on when `features.memory = true`:

1. **Memory bank** (`ENABLE_MEMORIES`): per-user store, visible and editable under *Settings → Personalization → Memory*. Seed it by hand with a few facts (who you are, language, tone, current projects) so there is something to inject from the first chat.
2. **Injection** (`ENABLE_MEMORY_SYSTEM_CONTEXT`): stored memories are added to the system context on every turn (2000-character budget per memory type).
3. **Background review** (`ENABLE_MEMORY_BACKGROUND_REVIEW`, every `MEMORIES_REVIEW_INTERVAL_TURNS = 10` turns): the chat model re-reads the recent conversation and adds, updates or deletes memories without an explicit tool call. This is the "remember things I said" path and works with any chat model.

Additionally the model can call `add_memory` / `search_memories` / `update_memory` / `delete_memory` itself ("remember that ..."). That needs **Function Calling: Native** on the model (*Admin → Models → edit → Advanced Params*), which Open WebUI stores per model in its DB, not in env. Do this once per chat model after a fresh install; `ENABLE_PERSISTENT_CONFIG=False` does not touch model records. Upstream notes that very small models pick memories poorly; `gpt-oss:20b` is the strongest tool-caller that fits in 16 GB VRAM.

Per-user: the Memory switch under *Settings → Personalization* must be on (it follows the server default when never touched).
- All sidecars are declared with `virtualisation.oci-containers`; each unit keeps its plain name (`comfyui.service`, `speaches.service`, `searxng.service`, `tika.service`, `jupyter.service`). Secrets from `/var/lib/ai-server/secrets/env` reach SearXNG and Jupyter one variable each (`-e SEARXNG_SECRET` / `-e JUPYTER_TOKEN` from the unit's EnvironmentFile), not as a whole env file.
- ComfyUI runs in a container built from `modules/ai-server/comfyui/Dockerfile` (thin layer on `rocm/pytorch:latest`, with a pinned ComfyUI release tag fetched as a tarball: the base image no longer ships git; bump `COMFYUI_VERSION` in the Dockerfile to upgrade). The build runs in the unit's `preStart` (the image is `pull = "never"`) and is layer-cached; first launch will pull the ~15-20 GB base image — be patient. Edits to the Dockerfile are picked up by `nixos-rebuild switch` because the build context path changes. To download a model, drop the file into `${dataDir}/models/checkpoints/` (e.g. SDXL from Hugging Face).
- ComfyUI is launched with `--lowvram` (UNet split across CPU+GPU, minimal CPU mirror of weights) and the container is hard-capped at 12 GB RAM (`--memory=12g`). The 16 GB host can't fit a CPU mirror of SDXL alongside Ollama's resident model, so without these flags the host swap-thrashes the moment a workflow runs. `PYTORCH_HIP_ALLOC_CONF=garbage_collection_threshold:0.8,max_split_size_mb:512` is also set so the HIP allocator returns VRAM more aggressively between runs.
- `OLLAMA_KEEP_ALIVE=5m` (down from 24h) — idle Ollama unloads its model so ComfyUI / Speaches have RAM headroom. The first chat turn after idle pays a ~3–5 s reload; the wake-proxy already cushions cold-start latency at the host level.
- ComfyUI and Speaches run with `--network=host` rather than publishing ports with `-p`. Docker-published ports are DNAT'd past the NixOS firewall and would be reachable on every interface; host-network listeners are filtered by it, so the `tailscale0`-only rule actually holds.
- **SearXNG, Tika, Jupyter** follow the same containerised pattern as ComfyUI / Speaches: `virtualisation.oci-containers` (docker backend, unit names kept via `serviceName`, logs in `journalctl -u <name>`, upstream images `pull = "always"`), loopback-only ports, persistent state under `/var/lib/<name>` where applicable. None are exposed on `tailscale0` — Open WebUI is the only consumer and calls them over `127.0.0.1`.
- **Secrets**: `ai-server-secrets.service` is a one-shot that runs on first boot, generates random Jupyter and SearXNG tokens via `openssl rand`, and writes them to `/var/lib/ai-server/secrets/env` (root:root 0600). Open WebUI, Jupyter and SearXNG all read this file via systemd `EnvironmentFile`, so the values are shared without ever appearing in the Nix store. To rotate, delete the file and `systemctl restart ai-server-secrets`.
- **`nomic-embed-text`** is added to `my.ai-server.models` so RAG/memory/search reranking work out of the box. ~270 MB pull, runs efficiently on either CPU or GPU.
- `ENABLE_PERSISTENT_CONFIG = "False"` is set on Open WebUI so env vars are authoritative on every boot. Without it, Open WebUI seeds env-var values into its DB the first time and then the DB wins — meaning UI edits silently override anything we declare here. With it disabled, this module is the single source of truth for admin/system settings; per-user preferences (each user's personal Audio overrides etc.) still persist normally.
- When `comfyui.enable = true`, Open WebUI is automatically wired to it via env vars (`ENABLE_IMAGE_GENERATION`, `IMAGE_GENERATION_ENGINE=comfyui`, `COMFYUI_BASE_URL=http://127.0.0.1:<port>`, `IMAGE_GENERATION_MODEL=sd_xl_base_1.0.safetensors`, `IMAGE_SIZE=1024x1024`, `IMAGE_STEPS=25`). To use a different default checkpoint, drop it into `${comfyui.dataDir}/models/checkpoints/` and edit the `IMAGE_GENERATION_MODEL` value in the module.
- **Custom workflows** are declarative via `comfyui.workflow` (path to a JSON file in ComfyUI's *API format*) and `comfyui.workflowNodes` (which nodes correspond to which generation parameters). A starter SDXL txt2img workflow ships at `modules/ai-server/comfyui/workflows/sdxl-base.json`; the matching node-mapping for it is shown below. Author new workflows by building the graph in ComfyUI, then **menu → Save (API Format)**; commit the JSON next to `sdxl-base.json` and reference it from your host config.

```nix
# in hosts/<host>/system.nix
my.ai-server.comfyui = {
  enable = true;
  workflow = ../../modules/ai-server/comfyui/workflows/sdxl-base.json;
  workflowNodes = [
    { type = "prompt";          node_ids = [ "6" ]; key = "text"; }
    { type = "negative_prompt"; node_ids = [ "7" ]; key = "text"; }
    { type = "model";           node_ids = [ "4" ]; key = "ckpt_name"; }
    { type = "width";           node_ids = [ "5" ]; }
    { type = "height";          node_ids = [ "5" ]; }
    { type = "steps";           node_ids = [ "3" ]; }
    { type = "seed";            node_ids = [ "3" ]; }
  ];
};
```
- Speaches runs an upstream image (no custom Dockerfile). When `voice.enable = true`:
  - Open WebUI is automatically wired to it via env vars (`AUDIO_STT_ENGINE=openai`, `AUDIO_STT_OPENAI_API_BASE_URL`, `AUDIO_STT_MODEL`, `AUDIO_TTS_ENGINE=openai`, `AUDIO_TTS_OPENAI_API_BASE_URL`, `AUDIO_TTS_MODEL`, `AUDIO_TTS_VOICE`). Fresh users inherit these as defaults; existing per-user overrides in *Settings → Audio* still win.
  - A oneshot `speaches-pull-models.service` POSTs to Speaches' `/v1/models/{id}` for the configured `sttModel` and `ttsModel` after the container is ready, so they're downloaded and cached without a UI step. Subsequent boots are fast (the cache lives in `voice.dataDir`).
  - To switch voices or try a different Whisper variant, change the corresponding option (`voice.sttModel`, `voice.ttsModel`, `voice.ttsVoice`) and rebuild; the pull service handles the download.
- Mobile browsers require **HTTPS** for `getUserMedia`. Use `https://chat.rydback.net` from a phone — the reverse-proxy on controller terminates TLS with a Let's Encrypt cert. `tailscale serve --https` was rejected as an option because the self-hosted headscale control server returns 404 on the cert-issuance endpoint.
- Verified on AMD Radeon RX 9070 XT (`gfx1201`, RDNA4) with Ryzen 7 5700X3D and 16 GB RAM.
- `OLLAMA_MAX_LOADED_MODELS=2` is sized for 16 GB system RAM (one chat model + the ~300 MB embedder). Bump it if RAM is upgraded.
- Bound to `0.0.0.0` but firewalled to `tailscale0`. Direct LAN access is intentionally closed — everything routes through controller's wake-proxy.

## Verification

```bash
# On the host
systemctl status ollama open-webui
rocminfo | grep gfx                                     # → gfx1201
ollama run gemma4:12b --verbose "Say hi" 2>&1 | tail -10  # eval rate: see docs/ai-scorecard.md
ollama ps                                                # after one chat turn: chat model AND nomic-embed-text, CONTEXT 16384

# ComfyUI (if enabled)
systemctl status comfyui
sudo docker logs comfyui 2>&1 | grep -E 'VRAM|gfx|Device:' | head

# From another tailnet host
curl https://llm.rydback.net/api/tags                   # Ollama API via HTTPS vhost
# In a browser: https://chat.rydback.net    (Open WebUI)
# In a browser: https://images.rydback.net  (ComfyUI)
# In a browser: https://voice.rydback.net   (Speaches Gradio UI)
```

Eval rate under ~10 tok/s means the model is on CPU — check `journalctl -u ollama` for Vulkan device-discovery errors. Memory end-to-end: state a fact in one chat, ask about it in a new chat; *Settings → Personalization → Memory* should list it (immediately with native function calling, otherwise after the next background review). First time Open WebUI is opened, register an admin account; subsequent users can register but admin approves them. ComfyUI's GPU detection should show `Device: cuda:0 AMD Radeon RX 9070 XT` and `AMD arch: gfx1201`.
