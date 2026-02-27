{ config, lib, ... }:
with lib;

{
  options.wayland-security = { enable = mkEnableOption "Wayland security configuration"; };

  config = mkIf config.wayland-security.enable {
    security.polkit.enable = true;
    programs.hyprlock.enable = true;
    # PAM configuration for swaylock (used by niri)
    security.pam.services.swaylock = {};
  };
}
