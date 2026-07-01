{ config, lib, pkgs, ... }:

with lib;

let cfg = config.ai-server;
in {
  options.ai-server = {
    enable = mkEnableOption "Local AI inference server (Ollama on AMD ROCm)";

    ollamaPort = mkOption {
      type = types.port;
      default = 11434;
      description = "Ollama HTTP API port; opened on the tailnet only.";
    };

    webuiPort = mkOption {
      type = types.port;
      default = 8081;
      description = "Open WebUI port; opened on the tailnet only.";
    };

    models = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "qwen3:8b" "qwen2.5-coder:14b" ];
      description = ''
        Models to keep present on the host. Pulled in the background after
        Ollama starts; existing models are left in place. Not destructive —
        removing a model from this list does not delete it.
      '';
    };

    comfyui = {
      enable = mkEnableOption "ComfyUI image generation (rocm/pytorch container)";

      port = mkOption {
        type = types.port;
        default = 8188;
        description = "ComfyUI HTTP port; opened on the tailnet only.";
      };

      dataDir = mkOption {
        type = types.path;
        default = "/var/lib/comfyui";
        description = ''
          Persistent state directory. Models, generated outputs, uploaded
          inputs, and the ComfyUI user DB live here and survive container
          restarts and image rebuilds.
        '';
      };

      workflow = mkOption {
        type = types.nullOr types.path;
        default = null;
        example = literalExpression "./comfyui/workflows/sdxl-base.json";
        description = ''
          ComfyUI workflow in **API format** that Open WebUI will use for
          image generation. Export from ComfyUI via the menu → "Save (API
          Format)" and commit the JSON alongside this module. When null,
          Open WebUI's built-in default txt2img workflow is used.
        '';
      };

      workflowNodes = mkOption {
        type = types.nullOr (types.listOf types.attrs);
        default = null;
        example = literalExpression ''
          [
            { type = "prompt";          node_ids = [ "6" ]; key = "text"; }
            { type = "negative_prompt"; node_ids = [ "7" ]; key = "text"; }
            { type = "model";           node_ids = [ "4" ]; key = "ckpt_name"; }
            { type = "width";           node_ids = [ "5" ]; }
            { type = "height";          node_ids = [ "5" ]; }
            { type = "steps";           node_ids = [ "3" ]; }
            { type = "seed";            node_ids = [ "3" ]; }
          ]
        '';
        description = ''
          Tells Open WebUI which nodes in the workflow correspond to which
          generation parameters. Each entry is an attrset with `type`,
          `node_ids` (list of strings — node IDs in the workflow JSON),
          and optionally `key` (the input-field name to inject into).
          Only relevant when `workflow` is set.
        '';
      };
    };

    voice = {
      enable = mkEnableOption "Speaches voice server (STT + TTS, OpenAI-API compatible)";

      port = mkOption {
        type = types.port;
        default = 8000;
        description = "Speaches HTTP API port; opened on the tailnet only.";
      };

      dataDir = mkOption {
        type = types.path;
        default = "/var/lib/speaches";
        description = "Persistent model cache (Hugging Face downloads).";
      };

      image = mkOption {
        type = types.str;
        default = "ghcr.io/speaches-ai/speaches:latest-cpu";
        description = ''
          Container image. The default is CPU-only — Whisper-large-v3-turbo
          and Piper/Kokoro voices run comfortably on CPU and avoid fighting
          Ollama/ComfyUI for VRAM.
        '';
      };

      sttModel = mkOption {
        type = types.str;
        default = "deepdml/faster-whisper-large-v3-turbo-ct2";
        description = ''
          Speech-to-text model id (must be present in Speaches' registry at
          `/v1/registry`). Pulled on activation if not already cached.
        '';
      };

      ttsModel = mkOption {
        type = types.str;
        default = "speaches-ai/Kokoro-82M-v1.0-ONNX-fp16";
        description = "Text-to-speech model id from Speaches' registry.";
      };

      ttsVoice = mkOption {
        type = types.str;
        default = "af_heart";
        description = ''
          Default TTS voice id. See `GET /v1/audio/speech/voices` for the
          full list of voices the TTS model exposes.
        '';
      };
    };

    search = {
      enable = mkEnableOption "SearXNG metasearch backend for Open WebUI web search";

      port = mkOption {
        type = types.port;
        default = 8082;
        description = "SearXNG HTTP port; loopback-only.";
      };

      dataDir = mkOption {
        type = types.path;
        default = "/var/lib/searxng";
        description = "Persistent state directory (caches, generated config).";
      };

      image = mkOption {
        type = types.str;
        default = "searxng/searxng:latest";
        description = "SearXNG container image.";
      };
    };

    documents = {
      enable = mkEnableOption "Apache Tika sidecar for parsing uploads in Open WebUI Knowledge";

      port = mkOption {
        type = types.port;
        default = 9998;
        description = "Tika HTTP port; loopback-only.";
      };

      image = mkOption {
        type = types.str;
        default = "apache/tika:latest";
        description = "Tika container image. The default ships a usable JVM and OCR baseline.";
      };
    };

    codeInterpreter = {
      enable = mkEnableOption "Jupyter container for the Open WebUI code-interpreter tool";

      port = mkOption {
        type = types.port;
        default = 8888;
        description = "Jupyter HTTP port; loopback-only.";
      };

      dataDir = mkOption {
        type = types.path;
        default = "/var/lib/jupyter";
        description = "Persistent state directory (notebook cache, kernel state).";
      };

      image = mkOption {
        type = types.str;
        default = "quay.io/jupyter/minimal-notebook:latest";
        description = "Jupyter container image.";
      };
    };

    features = {
      memory = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Open WebUI's long-term per-user memory feature.";
      };

      directConnections = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Allow users to attach OpenAPI / MCP tool servers in Open WebUI's
          Connections settings. Enabling this only exposes the UI — actual
          tool servers are added by users at runtime.
        '';
      };

      evaluationArena = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Enable message rating (thumbs up/down) and the model-comparison
          arena. Useful for the scorecard at `assets/ai-scorecard.md`.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    services.ollama = {
      enable = true;
      package = pkgs.ollama-rocm;
      host = "0.0.0.0";
      port = cfg.ollamaPort;
      loadModels = cfg.models;
      environmentVariables = {
        # 5 minutes — short enough that idle Ollama gives RAM back to the OS
        # so ComfyUI/Speaches can use it; long enough that consecutive chat
        # turns don't re-load the model. The wake-proxy already handles the
        # initial cold-start latency.
        OLLAMA_KEEP_ALIVE = "5m";
        OLLAMA_MAX_LOADED_MODELS = "1";
      };
    };

    services.open-webui = {
      enable = true;
      host = "0.0.0.0";
      port = cfg.webuiPort;
      environment = {
        OLLAMA_BASE_URL = "http://127.0.0.1:${toString cfg.ollamaPort}";
        WEBUI_AUTH = "True";
        # Without this, Open WebUI seeds env-var values into its DB on
        # first start and then the DB wins on every subsequent start —
        # which means UI edits override anything we declare here. Setting
        # this to False makes env vars authoritative every boot, so this
        # module is the single source of truth. Per-user preferences
        # (like a user's chosen STT engine in their personal Settings)
        # still persist; only admin/system config is overridden.
        ENABLE_PERSISTENT_CONFIG = "False";
      } // lib.optionalAttrs cfg.comfyui.enable {
        # Image generation via the local ComfyUI container. Server-to-server
        # over loopback, so no HTTPS hop. Switching the default model is a
        # one-line edit here; per-user overrides still work in the UI.
        ENABLE_IMAGE_GENERATION = "True";
        IMAGE_GENERATION_ENGINE = "comfyui";
        COMFYUI_BASE_URL = "http://127.0.0.1:${toString cfg.comfyui.port}";
        IMAGE_GENERATION_MODEL = "sd_xl_base_1.0.safetensors";
        IMAGE_SIZE = "1024x1024";
        IMAGE_STEPS = "25";
      } // lib.optionalAttrs (cfg.comfyui.enable && cfg.comfyui.workflow != null) {
        COMFYUI_WORKFLOW = builtins.readFile cfg.comfyui.workflow;
      } // lib.optionalAttrs (cfg.comfyui.enable && cfg.comfyui.workflowNodes != null) {
        COMFYUI_WORKFLOW_NODES = builtins.toJSON cfg.comfyui.workflowNodes;
      } // lib.optionalAttrs cfg.voice.enable {
        # STT + TTS via the local Speaches container (server-to-server over
        # loopback). These env vars set the defaults that new Open WebUI
        # users inherit; per-user overrides in Settings → Audio still win.
        AUDIO_STT_ENGINE = "openai";
        AUDIO_STT_OPENAI_API_BASE_URL = "http://127.0.0.1:${toString cfg.voice.port}/v1";
        AUDIO_STT_OPENAI_API_KEY = "dummy";
        AUDIO_STT_MODEL = cfg.voice.sttModel;
        AUDIO_TTS_ENGINE = "openai";
        AUDIO_TTS_OPENAI_API_BASE_URL = "http://127.0.0.1:${toString cfg.voice.port}/v1";
        AUDIO_TTS_OPENAI_API_KEY = "dummy";
        AUDIO_TTS_MODEL = cfg.voice.ttsModel;
        AUDIO_TTS_VOICE = cfg.voice.ttsVoice;
      } // {
        # RAG / embeddings via local Ollama. `nomic-embed-text` must be in
        # `ai-server.models` for this to work; it's pulled on activation.
        RAG_EMBEDDING_ENGINE = "ollama";
        RAG_EMBEDDING_MODEL = "nomic-embed-text";
        RAG_OLLAMA_BASE_URL = "http://127.0.0.1:${toString cfg.ollamaPort}";
        ENABLE_RAG_HYBRID_SEARCH = "True";
        # Title/tag/follow-up generation use the chat LLM and are on by
        # default; pinning them here makes the intent explicit.
        ENABLE_TITLE_GENERATION = "True";
        ENABLE_TAGS_GENERATION = "True";
        ENABLE_FOLLOW_UP_GENERATION = "True";
        ENABLE_AUTOCOMPLETE_GENERATION = "True";
        # UI niceties
        ENABLE_FOLDERS = "True";
        ENABLE_NOTES = "True";
      } // lib.optionalAttrs cfg.features.memory {
        ENABLE_MEMORY = "True";
      } // lib.optionalAttrs cfg.features.directConnections {
        # Lets users attach OpenAPI/MCP tool servers under Settings → Tools.
        ENABLE_DIRECT_CONNECTIONS = "True";
        MCP_INITIALIZE_TIMEOUT = "30";
      } // lib.optionalAttrs cfg.features.evaluationArena {
        ENABLE_MESSAGE_RATING = "True";
        ENABLE_EVALUATION_ARENA_MODELS = "True";
      } // lib.optionalAttrs cfg.search.enable {
        # Web search via local SearXNG container, JSON output enabled by the
        # bundled settings.yml. The `<query>` placeholder is filled by Open
        # WebUI per request. Both env-var prefixes are set because Open WebUI
        # v0.4+ renamed RAG_WEB_SEARCH_* → WEB_SEARCH_*; we ship both so the
        # module works across versions.
        ENABLE_WEB_SEARCH = "True";
        WEB_SEARCH_ENGINE = "searxng";
        WEB_SEARCH_RESULT_COUNT = "3";
        WEB_SEARCH_CONCURRENT_REQUESTS = "10";
        ENABLE_RAG_WEB_SEARCH = "True";
        RAG_WEB_SEARCH_ENGINE = "searxng";
        RAG_WEB_SEARCH_RESULT_COUNT = "3";
        RAG_WEB_SEARCH_CONCURRENT_REQUESTS = "10";
        SEARXNG_QUERY_URL = "http://127.0.0.1:${toString cfg.search.port}/search?q=<query>&format=json";
      } // lib.optionalAttrs cfg.documents.enable {
        # Apache Tika takes uploaded files and returns clean extracted text,
        # which Open WebUI then embeds for RAG. Massively better than the
        # built-in extractor for PDFs and Office docs.
        CONTENT_EXTRACTION_ENGINE = "tika";
        TIKA_SERVER_URL = "http://127.0.0.1:${toString cfg.documents.port}";
      } // lib.optionalAttrs cfg.codeInterpreter.enable {
        # The auth token comes from /var/lib/ai-server/secrets/env via
        # EnvironmentFile below (we don't inline the secret here so it
        # doesn't leak into the Nix store).
        ENABLE_CODE_INTERPRETER = "True";
        CODE_INTERPRETER_ENGINE = "jupyter";
        CODE_INTERPRETER_JUPYTER_URL = "http://127.0.0.1:${toString cfg.codeInterpreter.port}";
        CODE_INTERPRETER_JUPYTER_AUTH = "token";
      };
    };

    # Open WebUI reads the Jupyter token from this file; the same file is
    # consumed by jupyter.service so both ends share the value. The leading
    # `-` makes the file optional — if ai-server-secrets hasn't run yet, the
    # code-interpreter feature is silently degraded instead of preventing
    # the rest of Open WebUI from starting.
    systemd.services.open-webui.serviceConfig.EnvironmentFile = lib.mkIf cfg.codeInterpreter.enable
      "-/var/lib/ai-server/secrets/env";

    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [
      cfg.ollamaPort
      cfg.webuiPort
    ] ++ lib.optional cfg.comfyui.enable cfg.comfyui.port
      ++ lib.optional cfg.voice.enable cfg.voice.port;
      # NOTE: search/documents/codeInterpreter ports are deliberately not
      # exposed on tailscale0 — they're loopback-only, called server-to-server
      # by Open WebUI.

    environment.systemPackages = [ pkgs.rocmPackages.rocminfo ];

    # Some ROCm-aware tools expect a usable /opt/rocm/hip path.
    systemd.tmpfiles.rules = [
      "L+ /opt/rocm/hip - - - - ${pkgs.rocmPackages.clr}"
    ] ++ lib.optionals cfg.comfyui.enable [
      # 0775 root:wheel so admins can drop models in without sudo. The
      # container runs as root inside, so write access is unaffected.
      "d ${cfg.comfyui.dataDir} 0775 root wheel -"
      "d ${cfg.comfyui.dataDir}/models 0775 root wheel -"
      "d ${cfg.comfyui.dataDir}/models/checkpoints 0775 root wheel -"
      "d ${cfg.comfyui.dataDir}/models/vae 0775 root wheel -"
      "d ${cfg.comfyui.dataDir}/models/loras 0775 root wheel -"
      "d ${cfg.comfyui.dataDir}/models/clip 0775 root wheel -"
      "d ${cfg.comfyui.dataDir}/models/controlnet 0775 root wheel -"
      "d ${cfg.comfyui.dataDir}/models/upscale_models 0775 root wheel -"
      "d ${cfg.comfyui.dataDir}/models/embeddings 0775 root wheel -"
      "d ${cfg.comfyui.dataDir}/output 0775 root wheel -"
      "d ${cfg.comfyui.dataDir}/input 0775 root wheel -"
      "d ${cfg.comfyui.dataDir}/user 0775 root wheel -"
    ] ++ lib.optionals cfg.voice.enable [
      # 1000:1000 matches the container's `ubuntu` user so Speaches can write
      # the model cache. On home-desktop UID 1000 is also the admin user, so
      # files can still be dropped here manually without sudo.
      "d ${cfg.voice.dataDir} 0775 1000 1000 -"
      "d ${cfg.voice.dataDir}/hub 0775 1000 1000 -"
    ] ++ lib.optionals cfg.search.enable [
      "d ${cfg.search.dataDir} 0775 root wheel -"
    ] ++ lib.optionals cfg.codeInterpreter.enable [
      # jovyan (1000:100) is the container default user for jupyter images.
      "d ${cfg.codeInterpreter.dataDir} 0775 1000 100 -"
    ] ++ lib.optionals
      (cfg.codeInterpreter.enable || cfg.search.enable) [
      # Shared secrets dir, populated once by ai-server-secrets.service.
      "d /var/lib/ai-server 0750 root root -"
      "d /var/lib/ai-server/secrets 0750 root root -"
    ];

    # One-shot that generates random Jupyter and SearXNG secrets on first
    # boot. Both files live on disk under root:root 0600; consumers read
    # them via systemd EnvironmentFile. Re-runs are no-ops once the file
    # exists, so the values are stable across reboots until the file is
    # deleted manually.
    systemd.services.ai-server-secrets = lib.mkIf
      (cfg.codeInterpreter.enable || cfg.search.enable) {
      description = "Bootstrap shared secrets for ai-server sidecars";
      wantedBy = [ "multi-user.target" ];
      before = [ "open-webui.service" ]
        ++ lib.optional cfg.codeInterpreter.enable "jupyter.service"
        ++ lib.optional cfg.search.enable "searxng.service";

      path = [ pkgs.openssl ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };

      script = ''
        set -eu
        install -d -m 0750 /var/lib/ai-server/secrets
        if [ ! -f /var/lib/ai-server/secrets/env ]; then
          umask 077
          JT=$(openssl rand -hex 32)
          SS=$(openssl rand -hex 32)
          cat > /var/lib/ai-server/secrets/env <<EOF
        JUPYTER_TOKEN=$JT
        CODE_INTERPRETER_JUPYTER_AUTH_TOKEN=$JT
        SEARXNG_SECRET=$SS
        EOF
          chmod 0600 /var/lib/ai-server/secrets/env
        fi
      '';
    };

    systemd.services.comfyui = mkIf cfg.comfyui.enable {
      description = "ComfyUI image generation (ROCm container)";
      after = [ "docker.service" "network-online.target" ];
      requires = [ "docker.service" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "exec";
        # Build is layer-cached; first run pulls the ~15GB rocm/pytorch base.
        TimeoutStartSec = "2h";
        ExecStartPre = [
          "${pkgs.docker_29}/bin/docker build --pull=false -t comfyui-rocm:local ${./comfyui}"
          "-${pkgs.docker_29}/bin/docker rm -f comfyui"
        ];
        ExecStart = lib.concatStringsSep " " [
          "${pkgs.docker_29}/bin/docker run --rm --name=comfyui"
          "--device=/dev/kfd --device=/dev/dri"
          "--security-opt=seccomp=unconfined"
          # Hard memory cap so a runaway ComfyUI gets OOM-killed by the kernel
          # rather than dragging the whole host into swap thrashing. 12 GB is
          # generous for SDXL on this 16 GB host; bump if you start running
          # heavier image models (Flux dev) and have RAM headroom.
          "--memory=12g --memory-swap=12g"
          # Tell PyTorch's HIP allocator to release VRAM more aggressively
          # back to the OS / driver when tensors are freed. Helps when
          # switching between models or running many workflows in a row.
          "-e PYTORCH_HIP_ALLOC_CONF=garbage_collection_threshold:0.8,max_split_size_mb:512"
          "-p ${toString cfg.comfyui.port}:8188"
          "-v ${cfg.comfyui.dataDir}/models:/opt/ComfyUI/models"
          "-v ${cfg.comfyui.dataDir}/output:/opt/ComfyUI/output"
          "-v ${cfg.comfyui.dataDir}/input:/opt/ComfyUI/input"
          "-v ${cfg.comfyui.dataDir}/user:/opt/ComfyUI/user"
          # Override the image CMD so we can append --lowvram.
          # --lowvram: keep the UNet split across CPU+GPU and minimise the
          # CPU-side mirror of model weights. Slightly slower per generation,
          # dramatically less system RAM. Right fit for "VRAM > free RAM"
          # hosts like this one.
          "comfyui-rocm:local"
          "python main.py --listen 0.0.0.0 --port 8188 --lowvram"
        ];
        ExecStop = "${pkgs.docker_29}/bin/docker stop comfyui";
        Restart = "on-failure";
        RestartSec = "10s";
      };
    };

    systemd.services.speaches = mkIf cfg.voice.enable {
      description = "Speaches voice server (STT + TTS, OpenAI-API compatible)";
      after = [ "docker.service" "network-online.target" ];
      requires = [ "docker.service" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "exec";
        TimeoutStartSec = "30min";
        ExecStartPre = [
          "${pkgs.docker_29}/bin/docker pull ${cfg.voice.image}"
          "-${pkgs.docker_29}/bin/docker rm -f speaches"
        ];
        ExecStart = lib.concatStringsSep " " [
          "${pkgs.docker_29}/bin/docker run --rm --name=speaches"
          "-p ${toString cfg.voice.port}:8000"
          "-v ${cfg.voice.dataDir}:/home/ubuntu/.cache/huggingface"
          cfg.voice.image
        ];
        ExecStop = "${pkgs.docker_29}/bin/docker stop speaches";
        Restart = "on-failure";
        RestartSec = "10s";
      };
    };

    systemd.services.speaches-pull-models = mkIf cfg.voice.enable {
      description = "Pre-pull STT/TTS models into Speaches";
      after = [ "speaches.service" ];
      requires = [ "speaches.service" ];
      wantedBy = [ "multi-user.target" ];

      path = [ pkgs.curl ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        # First pull downloads from Hugging Face; can be slow.
        TimeoutStartSec = "30min";
      };

      script = ''
        set -u
        BASE="http://127.0.0.1:${toString cfg.voice.port}"

        # Wait for Speaches to be ready (it takes a few seconds after the
        # container is up before /v1/models responds).
        for _ in $(seq 1 60); do
          if curl -sf "$BASE/v1/models" >/dev/null; then
            break
          fi
          sleep 2
        done

        # Pull is idempotent — POST again on an already-cached model is fast.
        for model in '${cfg.voice.sttModel}' '${cfg.voice.ttsModel}'; do
          echo "speaches: pulling $model"
          curl -sf -X POST "$BASE/v1/models/$model" || \
            echo "speaches: pull failed for $model (will retry on next boot)"
        done
      '';
    };

    systemd.services.searxng = mkIf cfg.search.enable {
      description = "SearXNG metasearch backend for Open WebUI";
      after = [ "docker.service" "network-online.target" "ai-server-secrets.service" ];
      requires = [ "docker.service" "ai-server-secrets.service" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "exec";
        EnvironmentFile = "/var/lib/ai-server/secrets/env";
        TimeoutStartSec = "10min";
        ExecStartPre = [
          "${pkgs.docker_29}/bin/docker pull ${cfg.search.image}"
          "-${pkgs.docker_29}/bin/docker rm -f searxng"
        ];
        ExecStart = lib.concatStringsSep " " [
          "${pkgs.docker_29}/bin/docker run --rm --name=searxng"
          "-p 127.0.0.1:${toString cfg.search.port}:8080"
          "-e SEARXNG_BASE_URL=http://localhost:${toString cfg.search.port}/"
          # Forward SEARXNG_SECRET from the unit env (populated by
          # EnvironmentFile via ai-server-secrets.service) into the container.
          "-e SEARXNG_SECRET"
          "-v ${./searxng}/settings.yml:/etc/searxng/settings.yml:ro"
          "-v ${cfg.search.dataDir}:/var/cache/searxng"
          cfg.search.image
        ];
        ExecStop = "${pkgs.docker_29}/bin/docker stop searxng";
        Restart = "on-failure";
        RestartSec = "10s";
      };
    };

    systemd.services.tika = mkIf cfg.documents.enable {
      description = "Apache Tika document extraction sidecar";
      after = [ "docker.service" "network-online.target" ];
      requires = [ "docker.service" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "exec";
        TimeoutStartSec = "10min";
        ExecStartPre = [
          "${pkgs.docker_29}/bin/docker pull ${cfg.documents.image}"
          "-${pkgs.docker_29}/bin/docker rm -f tika"
        ];
        ExecStart = lib.concatStringsSep " " [
          "${pkgs.docker_29}/bin/docker run --rm --name=tika"
          "-p 127.0.0.1:${toString cfg.documents.port}:9998"
          cfg.documents.image
        ];
        ExecStop = "${pkgs.docker_29}/bin/docker stop tika";
        Restart = "on-failure";
        RestartSec = "10s";
      };
    };

    systemd.services.jupyter = mkIf cfg.codeInterpreter.enable {
      description = "Jupyter sandbox for Open WebUI code interpreter";
      after = [ "docker.service" "network-online.target" "ai-server-secrets.service" ];
      requires = [ "docker.service" "ai-server-secrets.service" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "exec";
        EnvironmentFile = "/var/lib/ai-server/secrets/env";
        TimeoutStartSec = "10min";
        ExecStartPre = [
          "${pkgs.docker_29}/bin/docker pull ${cfg.codeInterpreter.image}"
          "-${pkgs.docker_29}/bin/docker rm -f jupyter"
        ];
        ExecStart = lib.concatStringsSep " " [
          "${pkgs.docker_29}/bin/docker run --rm --name=jupyter"
          "-p 127.0.0.1:${toString cfg.codeInterpreter.port}:8888"
          "-v ${cfg.codeInterpreter.dataDir}:/home/jovyan/work"
          # docker `-e VAR` with no value forwards the value of VAR from the
          # current systemd unit's environment (populated by EnvironmentFile).
          # This avoids relying on systemd's $VAR substitution in ExecStart,
          # which Nix's escaping interfered with.
          "-e JUPYTER_TOKEN"
          "-e JUPYTER_ENABLE_LAB=yes"
          "-e GRANT_SUDO=no"
          "-e RESTARTABLE=yes"
          cfg.codeInterpreter.image
          "start-notebook.py"
          "--ServerApp.ip=0.0.0.0"
          "--ServerApp.allow_origin=*"
          "--ServerApp.disable_check_xsrf=True"
        ];
        ExecStop = "${pkgs.docker_29}/bin/docker stop jupyter";
        Restart = "on-failure";
        RestartSec = "10s";
      };
    };
  };
}
