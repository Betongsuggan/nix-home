{ config, lib, pkgs, ... }:
with lib;

{
  options.touchpad = {
    enable = mkEnableOption "Enable touchpad support";
  };

  config = mkIf config.touchpad.enable {
    services.libinput.enable = true;
    services.libinput.touchpad = {
      tapping = true;
      accelProfile = "flat";
      accelSpeed = "0";
      disableWhileTyping = true;
    };
    #hardware.keyboard.qmk.enable = true;
  };
}
