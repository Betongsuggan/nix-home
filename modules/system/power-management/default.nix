{ config, lib, pkgs, ... }:
with lib;

let
  cfg = config.br.power-management;
in
{
  options.br.power-management = {
    enable = mkEnableOption "Enable power management";
  };

  config = mkIf cfg.enable {
    services.tlp = {
      enable = true;
      settings = {
        START_CHARGE_THRESH_BAT0 = 75;
        STOP_CHARGE_THRESH_BAT0 = 80;
      };
    };
  };
}
