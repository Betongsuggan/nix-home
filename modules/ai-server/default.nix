{ config, lib, pkgs, ... }:

with lib;

let cfg = config.ai-server;
in {
  options.ai-server = {
    enable = mkEnableOption "Local AI inference server (Ollama on AMD ROCm)";

    port = mkOption {
      type = types.port;
      default = 11434;
      description = "Ollama HTTP API port; opened on the tailnet only.";
    };
  };

  config = mkIf cfg.enable {
    services.ollama = {
      enable = true;
      package = pkgs.ollama-rocm;
      host = "0.0.0.0";
      port = cfg.port;
      environmentVariables = {
        OLLAMA_KEEP_ALIVE = "24h";
        OLLAMA_MAX_LOADED_MODELS = "1";
      };
    };

    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ cfg.port ];

    environment.systemPackages = [ pkgs.rocmPackages.rocminfo ];

    # Some ROCm-aware tools expect a usable /opt/rocm/hip path.
    systemd.tmpfiles.rules = [
      "L+ /opt/rocm/hip - - - - ${pkgs.rocmPackages.clr}"
    ];
  };
}
