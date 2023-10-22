{ config, lib, pkgs, ... }:
with lib;

{
  options.touchpad = {
    enable = mkEnableOption "Enable touchpad support";
  };

  config = mkIf config.touchpad.enable {
    services.xserver.libinput.enable = true;
    services.xserver.libinput.touchpad.tapping = true;
    #hardware.keyboard.qmk.enable = true;
  };
}
