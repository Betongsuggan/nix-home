{ config, lib, ... }:
with lib;

{
  options.logitech = {
    enable = mkEnableOption "Enable Logitech hardware support";
  };

  config = mkIf config.logitech.enable {
    services.tumbler.enable = true;
    hardware.logitech.wireless.enable = true;
    hardware.logitech.wireless.enableGraphical = true;
  };
}