{ config, lib, pkgs, ... }:
with lib;

{
  options.power-management = {
    enable = mkEnableOption "Enable power management";
  };

  config = mkIf config.power-management.enable {
    services.tlp = {
      enable = true;
      settings = {
        START_CHARGE_THRESH_BAT0 = 75;
        STOP_CHARGE_THRESH_BAT0 = 80;
      };
    };
  };
}
