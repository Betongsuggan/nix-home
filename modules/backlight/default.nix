{ config, lib, pkgs, ... }:
with lib;

{
  options.backlight = {
    enable = mkEnableOption "Enable backlight control with proper permissions";
  };

  config = mkIf config.backlight.enable {
    # Add udev rules to allow video group to control backlight
    services.udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="backlight", RUN+="${pkgs.coreutils}/bin/chgrp video /sys/class/backlight/%k/brightness"
      ACTION=="add", SUBSYSTEM=="backlight", RUN+="${pkgs.coreutils}/bin/chmod g+w /sys/class/backlight/%k/brightness"
    '';

    # Ensure the video group exists
    users.groups.video = {};
  };
}
