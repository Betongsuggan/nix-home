{ config, lib, pkgs, ... }:
with lib;

let
  cfg = config.br.firefox;
in {
  options.br.firefox = {
    enable = mkEnableOption "Enable Firefox browser";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ firefox-wayland ];

    xdg = {
      portal = {
        enable = true;
        extraPortals = with pkgs; [
          xdg-desktop-portal-wlr
          xdg-desktop-portal-gtk
        ];
        #gtkUsePortal = true;
      };
    };
    environment.sessionVariables = {
      MOZ_ENABLE_WAYLAND = "1";
      XDG_CURRENT_DESKTOP = "sway"; 
    };
  };
}
