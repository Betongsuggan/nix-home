{ config, lib, pkgs, ... }:
with lib;

let
  cfg = config.br.firewall;
in {
  options.br.firewall = {
    enable = mkEnableOption "Enable Firewall";
    tcpPorts = mkOption {
      description = "Allowed incoming TCP port traffic";
      type = types.listOf types.port;
      default = [];
    };
    udpPorts = mkOption {
      description = "Allowed incoming UDP port traffic";
      type = types.listOf types.port;
      default = [];
    };
  };

  config = mkIf cfg.enable {
    networking.firewall = {
      enable = true;
      allowedTCPPorts = cfg.tcpPorts;
      allowedUDPPorts = cfg.udpPorts;
    };
  };
}
