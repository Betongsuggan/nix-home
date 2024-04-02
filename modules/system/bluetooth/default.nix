{ config, lib, pkgs, ... }:
with lib;

{
  options.bluetooth = {
    enable = mkEnableOption "Enable Bluetooth";
  };

  config = mkIf config.bluetooth.enable {
    services.blueman.enable = true;
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
  };
}
