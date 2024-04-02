{ config, lib, pkgs, ... }:
with lib;

{
  options.firewall = {
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

  config = mkIf config.firewall.enable {
    networking.firewall = {
      enable = true;
      allowedTCPPorts = config.firewall.tcpPorts;
      allowedUDPPorts = config.firewall.udpPorts;
    };
  };
}
