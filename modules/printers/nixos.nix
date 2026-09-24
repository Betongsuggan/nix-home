{
  config,
  lib,
  pkgs,
  ...
}:
with lib;

let
  cfg = config.my.printers;
in
{
  options.my.printers = {
    enable = mkEnableOption "Enable Printers";

    remoteDiscovery = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Run cups-browsed to discover printers shared by other machines on the
        LAN. It is pulled in by default whenever Avahi is enabled, runs from
        boot, and immediately connects to the CUPS socket -- which defeats the
        socket activation that would otherwise keep cupsd stopped. Turn it off
        on machines that print to a directly configured printer; Avahi itself
        (used for SMB share discovery) is unaffected.
      '';
    };
  };

  config = mkIf cfg.enable {
    # Printers and shit
    services.printing = {
      enable = true;
      browsing = true;
      defaultShared = true;
      browsed.enable = cfg.remoteDiscovery;
      drivers = [
        pkgs.gutenprint
        pkgs.hplip
        pkgs.brlaser
      ];
    };
  };
}
