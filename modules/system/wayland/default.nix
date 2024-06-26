{ config, lib, pkgs, ... }:
with lib;

{
  options.wayland = {
    enable = mkEnableOption "Wayland setup";
  };

  config = mkIf config.wayland.enable {
    security.polkit.enable = true;
    programs.light.enable = true;

    security.pam.services.swaylock = {
      text = "auth include login";
    };

    services.xserver = {
      enable = true;
      displayManager.gdm = {
        enable = true;
        wayland = true;
      };
    };
  };
}
