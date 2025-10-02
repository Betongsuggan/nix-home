{ config, lib, ... }:
with lib;

{
  options.wayland-security = { enable = mkEnableOption "Wayland security configuration"; };

  config = mkIf config.wayland-security.enable {
    security.polkit.enable = true;
    security.pam.services.swaylock = { text = "auth include login"; };
  };
}
