{ config, lib, pkgs, ... }:
with lib;

{
  options.firefox = {
    enable = mkEnableOption "Enable Firefox browser";
  };

  config = mkIf config.firefox.enable {
    home-manager.users.${config.user} = {
      home.sessionVariables = {
        MOZ_X11_EGL = "1";
        LIBVA_DRIVER_NAME = "i965";
      };
      programs.firefox = {
        enable = true;
        profiles.betongsuggan = {
          settings = {
              "media.ffmpeg.vaapi.enabled" = true;
              "media.ffvpx.enabled" = false;
              "media.av1.enabled" = false;
              "gfx.webrender.all" = true;
          };
          #extensions = with config.repos.rycee.firefox-addons; [
          #  vimium
          #  #1password
          #];
        };
      };
    };

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
      XDG_CURRENT_DESKTOP = "hyprland";
      GTK_USE_PORTAL = "1";
      NIXOS_OZONE_WL = "1";
    };
  };
}
