{
  config,
  lib,
  pkgs,
  ...
}:
with lib;

{
  options.my.touchpad = {
    enable = mkEnableOption "Enable touchpad support";
  };

  config = mkIf config.my.touchpad.enable {
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
