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
    ];

    environment.systemPackages = [ pkgs.rocmPackages.rocminfo ];

    # Some ROCm-aware tools expect a usable /opt/rocm/hip path.
    systemd.tmpfiles.rules = [
      "L+ /opt/rocm/hip - - - - ${pkgs.rocmPackages.clr}"
    ];
  };
}
