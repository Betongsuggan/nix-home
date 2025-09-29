{ config, lib, pkgs, ... }:
with lib;

{
  options.firefoxSystem = {
    enable = mkEnableOption "Enable Firefox system support";
  };

  config = mkIf config.firefoxSystem.enable {
    # System-level Firefox support (XDG portals and environment)
    xdg = {
      portal = {
        enable = true;
        extraPortals = with pkgs; [
          xdg-desktop-portal-wlr
          xdg-desktop-portal-gtk
        ];
      };
    };
    environment.sessionVariables = {
      MOZ_ENABLE_WAYLAND = "1";
      MOZ_WEBRENDER = "1";
      XDG_CURRENT_DESKTOP = "hyprland";
      GTK_USE_PORTAL = "1";
      NIXOS_OZONE_WL = "1";
    };
  };
}
