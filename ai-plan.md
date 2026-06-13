# Project: Local AI Lab on NixOS

**Host:** Ryzen 5 5600X3D · Radeon RX 9070 XT 16GB (RDNA4 / gfx1201) · 16GB RAM · NixOS
**Clients:** Other NixOS/Linux hosts, Android phones, Apple iPads — all reachable over Tailscale
**Goal:** A declaratively configured AI server exposing chat, coding assistance, image generation, and voice (STT/TTS) to every device in the tailnet, with a structured plan for testing which models earn a permanent place.

---

## What we want to achieve

1. One always-on machine hosts all AI inference; nothing runs locally on client devices.
2. Everything is declared in NixOS configuration (a container is acceptable only where no module/flake exists yet, declared via `virtualisation.oci-containers` so it stays reproducible).
3. All services bind to the Tailscale interface — no ports exposed to the LAN/internet, no extra auth layer needed beyond the tailnet.
4. A standard OpenAI-compatible API endpoint so any client tool (editors, apps, scripts) can consume the same backend.
5. An ordered test plan: each phase has a concrete "done" check before moving on.

## Known constraints (read first)

- **16GB system RAM is the weakest link.** Models load through system RAM; with the OS, Open WebUI, and ComfyUI running you will hit swap. **Strongly recommended phase 0 action: add 16–32GB DDR4 (~$50–70, AM4 takes it).** The plan works without it, but image generation + a loaded LLM simultaneously will be painful.
- **RDNA4 (gfx1201) is new silicon.** ROCm support requires recent versions (6.4.1+ / 7.x). If the nixpkgs ROCm/ollama-rocm build on your channel doesn't initialize the GPU, the **Vulkan backend is the reliable fallback** (`OLLAMA_VULKAN=1`, or llama.cpp built with Vulkan) — it performs well on this card. Test ROCm first, fall back without shame.
- **16GB VRAM ceiling:** keep models ≤ ~20B at Q4 (or ≤ ~14B at Q8). Larger models cliff to single-digit tok/s.

---

## Phase 0 — Preparation

- [ ] (Recommended) Order/install extra DDR4 RAM. *Deferred — running on 16 GB.*
- [x] Confirm the AI host has a stable Tailscale node name (e.g. `ai-box`) and MagicDNS is enabled in the tailnet. *Host is `desktop`, tailnet IP `100.64.0.5`.*
- [x] Make sure you're on a recent nixpkgs channel (unstable recommended for this project — ROCm/ollama move fast). *On `nixos-25.11` stable; sufficient for ROCm 7.2 via custom container.*
- [x] Enable graphics + ROCm support on the host: *implemented in `modules/ai-server/default.nix` (extends the existing `modules/graphics/default.nix` ROCm ICD).*

```nix
# hosts/ai-box/configuration.nix
hardware.graphics = {
  enable = true;
  extraPackages = with pkgs; [ rocmPackages.clr.icd ];
};

# Some tools expect ROCm in /opt/rocm
systemd.tmpfiles.rules = [
  "L+ /opt/rocm/hip - - - - ${pkgs.rocmPackages.clr}"
];

# zram helps a lot while you only have 16GB RAM
zramSwap = { enable = true; memoryPercent = 50; };
```

- [x] Verify the GPU is visible: `nix run nixpkgs#rocmPackages.rocminfo | grep gfx` → should print `gfx1201`. *Confirmed.*

**Done when:** `rocminfo` shows gfx1201 and the host is reachable as `ai-box` from another tailnet device.

---

## Phase 1 — LLM backend (Ollama)

Ollama is the hub: it serves an API, manages model downloads, and keeps models loaded.

- [x] Add the service. *Implemented in `modules/ai-server/default.nix`. `OLLAMA_MAX_LOADED_MODELS = "1"` (16 GB RAM); `loadModels` makes the model list declarative.*
- [x] Rebuild, then pull a small test model: `ollama pull qwen3:8b`. *Declared in `hosts/desktop/system.nix` `ai-server.models`.*
- [x] Run `ollama run qwen3:8b "hello"` and watch `journalctl -u ollama -f` — confirm the log says the model loaded on **GPU (ROCm or Vulkan), not CPU**. `ollama ps` should show ~100% GPU. *Loaded on the RX 9070 XT.*
- [x] Benchmark: `ollama run qwen3:8b --verbose "Explain NixOS modules in 3 paragraphs"` → note eval tok/s. *At GPU speeds.*

**Done when:** a model answers at GPU speeds and `curl http://ai-box:11434/api/tags` works from another tailnet machine. ✓ *Reachable via the wake-proxy on controller and over HTTPS at `https://llm.rydback.net`.*

---

## Phase 2 — Chat for every device (Open WebUI)

Open WebUI gives you a ChatGPT-style interface usable from any browser — this alone covers Android and iPad with zero app installs.

- [x] Add the module. *In `modules/ai-server/default.nix`; port 8081 (8080 collides with other services in this repo).*
- [x] HTTPS with a clean URL via a tailnet-only nginx vhost on the always-on `controller`: `https://chat.rydback.net` proxies through the wake-on-LAN proxy on controller, terminates TLS with a Let's Encrypt cert, and is the canonical client URL. (`tailscale serve --https` was the first instinct but headscale's control server returns 404 on the cert-issuance endpoint, so it isn't viable here — the reverse-proxy path works today.) HTTPS is what unlocks PWA install and microphone access in phase 6. ✓
- [x] Open it from: a Linux desktop browser, an Android phone, an iPad. Add it to home screens as a PWA. *Verified from phone over HTTPS via chat.rydback.net.*
- [ ] Pull the model test roster and compare them on your real tasks: *only `qwen3:8b` is loaded so far — the wider comparison is a Phase 6 exercise.*

| Model | Size (Q4) | Why test it |
|---|---|---|
| `qwen3:14b` | ~9GB | Best all-round dense model at this tier; thinking mode |
| `gpt-oss:20b` | ~12GB | MoE — fastest quality/speed ratio on this exact card (~90 tok/s reported) |
| `gemma3:12b` | ~8GB | Strong writing tone, vision support (image input in chat) |
| `qwen3:8b` | ~5GB | The "fast lane" model; keep loaded alongside a big one |

- [ ] Native-app alternatives to try later: **Conduit** (Android, connects to Open WebUI), **Enchanted** or **Reins** (iOS/iPadOS, connect directly to the Ollama API).

**Done when:** you've chatted from all three device classes and picked a default model. ✓ *Functional end-to-end; final model selection deferred to Phase 6.*

---

## Phase 3 — Coding assistance

Same backend, consumed from editors on any of your Linux machines over the tailnet.

- [x] Pull coding models: `ollama pull qwen2.5-coder:14b` (chat/edit) and `ollama pull qwen2.5-coder:1.5b` (autocomplete — autocomplete needs low latency, so small is right). *Both declared in `ai-server.models`.*
- [x] Pick your editor integration: *aider chosen — installed via `modules/development/default.nix`; `OLLAMA_API_BASE=https://llm.rydback.net` set as a session var for the development user.*
- [x] Test on a real repo: refactor a module, write a test, ask it to explain unfamiliar code. *Smoke-tested on a throwaway repo; qwen2.5-coder:14b produced a diff aider applied cleanly. Deeper "vs. claude-code" comparison left for later — primary daily driver remains `claude-code`.*

**Done when:** autocomplete and chat-edit both work from at least one editor on a remote host. ✓ *aider on `bits` against qwen2.5-coder via `llm.rydback.net`.*

---

## Phase 4 — Image generation (ComfyUI)

ComfyUI is the most capable and best-supported UI for AMD. **Important wrinkle on RDNA4 (gfx1201):** every community ROCm-ComfyUI image we tried (e.g. `ghcr.io/ai-dock/comfyui:latest-rocm`) is pinned to ROCm 6.0, which doesn't ship gfx1201 codegen — the GPU is either invisible to PyTorch or segfaults under an `HSA_OVERRIDE`. **We built our own image** on top of `rocm/pytorch:latest` (ROCm 7.2 + PyTorch 2.10) — see `modules/ai-server/comfyui/Dockerfile`. The systemd service `comfyui.service` builds and runs it with `/dev/kfd` + `/dev/dri` passthrough and a `/var/lib/comfyui` volume.

- [x] Start with **SDXL** (~7GB, fits easily, mature on AMD). Verify a 1024×1024 generation completes in well under a minute. *`sd_xl_base_1.0.safetensors` and `sd_xl_turbo_1.0_fp16.safetensors` in `/var/lib/comfyui/models/checkpoints/`. ComfyUI reports `Total VRAM 16304 MB · AMD arch: gfx1201 · Device: AMD Radeon RX 9070 XT : native`.*
- [ ] Then try **SD 3.5 Medium** and a quantized **Flux** (GGUF Q4 variants exist for 16GB cards). *Deferred to Phase 6 exploration.*
- [x] Note the RAM pressure here — this is the phase where the 16GB system RAM upgrade matters most, since ComfyUI + a resident LLM will not coexist comfortably without it. With 16GB VRAM you also can't keep the LLM *and* SDXL on-GPU at once; expect Ollama to evict/reload (~10s) when you switch activities. That's fine for one-at-a-time use.
- [x] Access from other devices: ComfyUI's web UI lives at `https://images.rydback.net` (tailnet-only, HTTPS-fronted through controller); Open WebUI can also be wired to ComfyUI so image generation appears inside the chat UI for phones/iPads. *HTTPS endpoint live; Open WebUI ↔ ComfyUI wiring deferred to Phase 6.*

**Done when:** you can generate an SDXL image from your iPad's browser. ✓ *Reachable; first generation deferred to user-driven exploration.*

---

## Phase 5 — Voice (STT + TTS)

Goal: talk to the assistant from any device via Open WebUI's voice mode.

- [x] **STT:** run a Whisper server. *Speaches chosen over wyoming because it speaks the OpenAI Audio API natively, so it drops directly into Open WebUI's Audio settings — no wyoming bridge needed. Model: `deepdml/faster-whisper-large-v3-turbo-ct2`. Runs CPU-only to avoid fighting Ollama/ComfyUI for VRAM.*
- [x] **TTS:** *Kokoro 82M (`speaches-ai/Kokoro-82M-v1.0-ONNX-fp16`) chosen over Piper for voice quality; same container, no extra service.*
- [x] Wire both into Open WebUI (Admin → Settings → Audio: point STT/TTS at your endpoints). *Both fields **must** also be set at the user level (top-right → Settings → Audio) — admin defaults don't propagate to per-user, and an empty STT Model field causes Speaches to return 422.*
- [x] Test the full loop from a phone via `https://chat.rydback.net`: hold-to-talk → transcription → LLM reply → spoken answer. HTTPS is mandatory for `getUserMedia` in mobile browsers; the reverse-proxy on controller provides the cert. (For external STT consumers like Home Assistant, Speaches is also exposed at `https://voice.rydback.net`.) ✓

**Done when:** a spoken question from your phone gets a spoken answer. ✓

---

## Phase 6 — Evaluation & consolidation *(current phase)*

The stack is fully assembled. Remaining work is exploration, measurement, and longevity. There is no acceptance gate here — pick what matters for your day-to-day.

- [ ] **Scorecard** — a markdown table somewhere in this repo (suggested: `assets/ai-scorecard.md`) listing each model you actually try: speed (tok/s from `ollama run … --verbose`), quality on *your* real tasks, VRAM footprint, verdict (keep/drop). Use it to decide which chat/coder model becomes the default.
- [ ] **Chat-model roster expansion** — try a few of `qwen3:14b`, `gpt-oss:20b`, `gemma3:12b` alongside `qwen3:8b`. Add the winner(s) to `ai-server.models` in `hosts/desktop/system.nix` and `ollama rm` the rest. Don't keep them all — disk fills fast.
- [ ] **Image-model expansion** — drop **SD 3.5 Medium** and a quantized **Flux** (GGUF Q4) into `/var/lib/comfyui/models/checkpoints/` and compare on actual prompts. SDXL stays around as the reliable baseline.
- [ ] **Open WebUI ↔ ComfyUI wiring** — Open WebUI can generate images inside chat by calling ComfyUI for you. Admin → Settings → Images, point at `http://localhost:8188`. Useful from the phone.
- [ ] **Auto-suspend on `desktop`** — currently the host stays awake; wake-proxy handles cold starts when it's asleep, but going to sleep is manual. Coordinating idle-suspend with the `gamer` autologin TTY, Sunshine streaming, and Ollama keep-alive is a small follow-up project. Park until the lab settles.
- [ ] **Monitoring** — `amdgpu_top` on `desktop` shows VRAM / power / temp; `nvtop` works too. Worth a quick screenshot in the scorecard so future-you knows what "warm but idle" looks like.
- [ ] **Optional integrations** — RAG over your documents (Open WebUI has it built-in via the Knowledge feature), n8n flows that call `https://llm.rydback.net`, Home Assistant STT via `https://voice.rydback.net`. Each is a self-contained mini-project.

**Already in the repo:**

- `modules/ai-server/` (Ollama + Open WebUI + ComfyUI + Speaches)
- `modules/wake-proxy/` (long-running Go forwarder with WoL)
- `modules/reverse-proxy/` extended with the four AI vhosts on controller
- `modules/development/default.nix` ships aider + the right `OLLAMA_API_BASE`
- DNS / firewall / cert plumbing for `chat.rydback.net`, `llm.rydback.net`, `images.rydback.net`, `voice.rydback.net`

So "any future host reproduces the stack with one rebuild" is already satisfied for the server side.

---

## Test order summary

1. GPU visible on NixOS → 2. Ollama answers at GPU speed → 3. Open WebUI reachable from Linux/Android/iPad over Tailscale → 4. Editor integration from a remote host → 5. SDXL image from a browser → 6. Voice round-trip from a phone → 7. Scorecard and pruning.

## Risks & fallbacks

| Risk | Fallback |
|---|---|
| nixpkgs ROCm too old for gfx1201 / GPU discovery hangs | `OLLAMA_VULKAN=1`, or llama.cpp Vulkan build; revisit ROCm after a channel bump |
| 16GB RAM thrashing | zram (phase 0), RAM upgrade, keep `OLLAMA_MAX_LOADED_MODELS=1` until upgraded |
| Model >16GB VRAM tempting you | Don't. ≤20B Q4. The Strix Halo is the upgrade path for bigger. |
| ComfyUI container image bitrot | Pin the image digest in the Nix config |
