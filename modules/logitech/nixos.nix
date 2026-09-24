{ config, lib, ... }:
with lib;

{
  options.my.logitech = {
    enable = mkEnableOption "Enable Logitech hardware support";
  };

  config = mkIf config.my.logitech.enable {
    services.tumbler.enable = true;
    hardware.logitech.wireless.enable = true;
    hardware.logitech.wireless.enableGraphical = true;
  };
}
