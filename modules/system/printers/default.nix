{ config, lib, pkgs, ... }:
with lib;

let
  cfg = config.br.printers;
in {
  options.br.printers = {
    enable = mkEnableOption "Enable Printers";
  };

  config = mkIf cfg.enable {
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
