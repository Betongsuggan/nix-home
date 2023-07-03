{ config, lib, pkgs, ... }:
with lib;

let
  cfg = config.br.firefox;
in
{
  options.br.firefox = {
    enable = mkEnableOption "Enable Firefox browser";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ firefox-wayland linux-firmware ];

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
      XDG_CURRENT_DESKTOP = "sway";
      GTK_USE_PORTAL = "1";
      NIXOS_OZONE_WL = "1";
    };
  };
}
