{
  config,
  lib,
  pkgs,
  ...
}:
with lib;

{
  options.my.firewall = {
    enable = mkEnableOption "Enable Firewall";
    tcpPorts = mkOption {
      description = "Allowed incoming TCP port traffic";
      type = types.listOf types.port;
      default = [ ];
    };
    udpPorts = mkOption {
      description = "Allowed incoming UDP port traffic";
      type = types.listOf types.port;
      default = [ ];
    };
  };

  config = mkIf config.my.firewall.enable {
    networking.firewall = {
      enable = true;
      allowedTCPPorts = config.my.firewall.tcpPorts;
      allowedUDPPorts = config.my.firewall.udpPorts;
    };
  };
}
