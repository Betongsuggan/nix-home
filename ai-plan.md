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

- [ ] (Recommended) Order/install extra DDR4 RAM.
- [ ] Confirm the AI host has a stable Tailscale node name (e.g. `ai-box`) and MagicDNS is enabled in the tailnet.
- [ ] Make sure you're on a recent nixpkgs channel (unstable recommended for this project — ROCm/ollama move fast).
- [ ] Enable graphics + ROCm support on the host:

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

- [ ] Verify the GPU is visible: `nix run nixpkgs#rocmPackages.rocminfo | grep gfx` → should print `gfx1201`.

**Done when:** `rocminfo` shows gfx1201 and the host is reachable as `ai-box` from another tailnet device.

---

## Phase 1 — LLM backend (Ollama)

Ollama is the hub: it serves an API, manages model downloads, and keeps models loaded.

- [ ] Add the service:

```nix
services.ollama = {
  enable = true;
  package = pkgs.ollama-rocm;
  # Listen on all interfaces; firewall restricts to tailnet below
  host = "0.0.0.0";
  port = 11434;
  environmentVariables = {
    OLLAMA_KEEP_ALIVE = "24h";     # keep models warm
    OLLAMA_MAX_LOADED_MODELS = "2";
    # If ROCm fails to init the GPU, uncomment to use Vulkan instead:
    # OLLAMA_VULKAN = "1";
  };
  # Only if ROCm misdetects the card (check logs first):
  # rocmOverrideGfx = "12.0.1";
};

networking.firewall.interfaces."tailscale0".allowedTCPPorts = [
  11434  # ollama
  8080   # open-webui (phase 2)
  8188   # comfyui (phase 5)
];
```

- [ ] Rebuild, then pull a small test model: `ollama pull qwen3:8b`
- [ ] Run `ollama run qwen3:8b "hello"` and watch `journalctl -u ollama -f` — confirm the log says the model loaded on **GPU (ROCm or Vulkan), not CPU**. `ollama ps` should show ~100% GPU.
- [ ] Benchmark: `ollama run qwen3:8b --verbose "Explain NixOS modules in 3 paragraphs"` → note eval tok/s. Expect roughly 60–80 tok/s for an 8–9B Q4 model; if you see <10 tok/s you're on CPU — fix before continuing.

**Done when:** a model answers at GPU speeds and `curl http://ai-box:11434/api/tags` works from another tailnet machine.

---

## Phase 2 — Chat for every device (Open WebUI)

Open WebUI gives you a ChatGPT-style interface usable from any browser — this alone covers Android and iPad with zero app installs.

- [ ] Add the module:

```nix
services.open-webui = {
  enable = true;
  host = "0.0.0.0";
  port = 8080;
  environment = {
    OLLAMA_BASE_URL = "http://127.0.0.1:11434";
    WEBUI_AUTH = "True";  # per-user accounts/history
  };
};
```

- [ ] (Nice-to-have) HTTPS with a clean URL via `tailscale serve --bg --https=443 http://localhost:8080` → `https://ai-box.<tailnet>.ts.net`. iPads in particular are happier with HTTPS (enables PWA install, mic access for phase 6).
- [ ] Open it from: a Linux desktop browser, an Android phone, an iPad. Add it to home screens as a PWA.
- [ ] Pull the model test roster and compare them on your real tasks:

| Model | Size (Q4) | Why test it |
|---|---|---|
| `qwen3:14b` | ~9GB | Best all-round dense model at this tier; thinking mode |
| `gpt-oss:20b` | ~12GB | MoE — fastest quality/speed ratio on this exact card (~90 tok/s reported) |
| `gemma3:12b` | ~8GB | Strong writing tone, vision support (image input in chat) |
| `qwen3:8b` | ~5GB | The "fast lane" model; keep loaded alongside a big one |

- [ ] Native-app alternatives to try later: **Conduit** (Android, connects to Open WebUI), **Enchanted** or **Reins** (iOS/iPadOS, connect directly to the Ollama API).

**Done when:** you've chatted from all three device classes and picked a default model.

---

## Phase 3 — Coding assistance

Same backend, consumed from editors on any of your Linux machines over the tailnet.

- [ ] Pull coding models: `ollama pull qwen2.5-coder:14b` (chat/edit) and `ollama pull qwen2.5-coder:1.5b` (autocomplete — autocomplete needs low latency, so small is right).
- [ ] Pick your editor integration:
  - **Continue** (VS Code/JetBrains): point it at `http://ai-box:11434`, set the 14b model for chat and 1.5b for tab-autocomplete.
  - **Zed**: built-in Ollama provider, just set the host URL.
  - **aider** (terminal, fits a Nix workflow well): `aider --model ollama/qwen2.5-coder:14b` with `OLLAMA_API_BASE=http://ai-box:11434`.
- [ ] Test on a real repo: refactor a module, write a test, ask it to explain unfamiliar code. Judge usefulness honestly vs. cloud assistants — local shines for privacy and unlimited usage, not frontier intelligence.

**Done when:** autocomplete and chat-edit both work from at least one editor on a remote host.

---

## Phase 4 — Image generation (ComfyUI)

ComfyUI is the most capable and best-supported UI for AMD. There is no official NixOS module yet, so use either a community flake (e.g. a `comfyui-nix` flake input) or a declared container — both stay declarative:

```nix
# Pragmatic declarative option: rocm/pytorch-based container
virtualisation.oci-containers.containers.comfyui = {
  image = "ghcr.io/<maintained-rocm-comfyui-image>";  # pick a current RDNA4-capable image
  ports = [ "8188:8188" ];
  devices = [ "/dev/kfd" "/dev/dri" ];
  volumes = [ "/var/lib/comfyui:/data" ];
};
```

- [ ] Start with **SDXL** (~7GB, fits easily, mature on AMD). Verify a 1024×1024 generation completes in well under a minute.
- [ ] Then try **SD 3.5 Medium** and a quantized **Flux** (GGUF Q4 variants exist for 16GB cards).
- [ ] Note the RAM pressure here — this is the phase where the 16GB system RAM upgrade matters most, since ComfyUI + a resident LLM will not coexist comfortably without it. With 16GB VRAM you also can't keep the LLM *and* SDXL on-GPU at once; expect Ollama to evict/reload (~10s) when you switch activities. That's fine for one-at-a-time use.
- [ ] Access from other devices: ComfyUI's web UI works over the tailnet at `http://ai-box:8188`; Open WebUI can also be wired to ComfyUI so image generation appears inside the chat UI for phones/iPads.

**Done when:** you can generate an SDXL image from your iPad's browser.

---

## Phase 5 — Voice (STT + TTS)

Goal: talk to the assistant from any device via Open WebUI's voice mode.

- [ ] **STT:** run a Whisper server. Options in order of preference: `services.wyoming.faster-whisper` (existing NixOS module), or **Speaches** (OpenAI-compatible STT+TTS server) as a declared container. Model: `whisper-large-v3-turbo` (fast, ~1.5GB) — it can run on CPU acceptably if the GPU is busy.
- [ ] **TTS:** **Piper** (NixOS module exists via wyoming-piper; tiny, instant, decent voices) first; try **Kokoro** via Speaches if you want noticeably nicer voices.
- [ ] Wire both into Open WebUI (Admin → Settings → Audio: point STT/TTS at your endpoints).
- [ ] Test the full loop from a phone: hold-to-talk → transcription → LLM reply → spoken answer. HTTPS via `tailscale serve` is required for microphone access in mobile browsers.

**Done when:** a spoken question from your phone gets a spoken answer.

---

## Phase 6 — Evaluation & consolidation

- [ ] Keep a simple scorecard (a markdown table in your repo) per model: speed (tok/s), quality on *your* tasks, RAM/VRAM footprint, verdict (keep/drop).
- [ ] Settle on a steady-state roster, e.g.: one daily-driver chat model + one autocomplete model + SDXL + whisper-turbo + piper. Remove the rest (`ollama rm ...`) — disk fills fast.
- [ ] Commit all of it to your NixOS config repo so any future host (a Strix Halo box, say) reproduces the whole stack with one rebuild.
- [ ] Optional next steps once stable: RAG over your documents (Open WebUI has it built in), n8n/Home Assistant integration via the OpenAI-compatible API, monitoring with `amdgpu_top`.

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
