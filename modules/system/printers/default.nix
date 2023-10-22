{ config, lib, pkgs, ... }:
with lib;

{
  options.printers = {
    enable = mkEnableOption "Enable Printers";
  };

  config = mkIf config.printers.enable {
    # Printers and shit
    services.printing = {
      enable = true;
      browsing = true;
      defaultShared = true;
      drivers = [
        pkgs.gutenprint
        pkgs.hplip
        pkgs.brlaser
      ];
    };
  };
}
