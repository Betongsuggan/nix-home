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
        OLLAMA_KEEP_ALIVE = "24h";
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
      };
    };

    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [
      cfg.ollamaPort
      cfg.webuiPort
    ] ++ lib.optional cfg.comfyui.enable cfg.comfyui.port
      ++ lib.optional cfg.voice.enable cfg.voice.port;

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
      "d ${cfg.voice.dataDir} 0775 root wheel -"
    ];

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
          "${pkgs.docker}/bin/docker build --pull=false -t comfyui-rocm:local ${./comfyui}"
          "-${pkgs.docker}/bin/docker rm -f comfyui"
        ];
        ExecStart = lib.concatStringsSep " " [
          "${pkgs.docker}/bin/docker run --rm --name=comfyui"
          "--device=/dev/kfd --device=/dev/dri"
          "--security-opt=seccomp=unconfined"
          "-p ${toString cfg.comfyui.port}:8188"
          "-v ${cfg.comfyui.dataDir}/models:/opt/ComfyUI/models"
          "-v ${cfg.comfyui.dataDir}/output:/opt/ComfyUI/output"
          "-v ${cfg.comfyui.dataDir}/input:/opt/ComfyUI/input"
          "-v ${cfg.comfyui.dataDir}/user:/opt/ComfyUI/user"
          "comfyui-rocm:local"
        ];
        ExecStop = "${pkgs.docker}/bin/docker stop comfyui";
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
          "${pkgs.docker}/bin/docker pull ${cfg.voice.image}"
          "-${pkgs.docker}/bin/docker rm -f speaches"
        ];
        ExecStart = lib.concatStringsSep " " [
          "${pkgs.docker}/bin/docker run --rm --name=speaches"
          "-p ${toString cfg.voice.port}:8000"
          "-v ${cfg.voice.dataDir}:/home/ubuntu/.cache/huggingface"
          cfg.voice.image
        ];
        ExecStop = "${pkgs.docker}/bin/docker stop speaches";
        Restart = "on-failure";
        RestartSec = "10s";
      };
    };
  };
}
