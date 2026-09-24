# System half of window-manager: the xdg-desktop-portal setup each
# compositor needs, derived from the backends the host's users run.
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib;

let
  uses =
    backend:
    inputs.self.lib.anyHomeUser config (
      u: u.my.window-manager.enable && u.my.window-manager.backend == backend
    );
in
{
  config = mkMerge [
    (mkIf (uses "hyprland") {
      xdg.portal = {
        enable = true;
        extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
        config.common.default = "*";
      };
    })

    (mkIf (uses "niri") {
      xdg.portal = {
        enable = true;
        extraPortals = [
          pkgs.xdg-desktop-portal-gtk
          pkgs.xdg-desktop-portal-gnome
        ];
        # niri ships niri-portals.conf
        configPackages = [ pkgs.niri-stable ];
      };
    })
  ];
}
