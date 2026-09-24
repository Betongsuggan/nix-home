{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

with lib;

let
  anyUserEnabled = inputs.self.lib.anyHomeUser config (u: u.my.chromium.enable);
in
{
  config = mkIf anyUserEnabled {
    # Chromium's Save As dialog goes through xdg-desktop-portal's FileChooser
    # interface. When XDG_CURRENT_DESKTOP=gnome (e.g. niri sets this for screen
    # sharing), the gnome portal handles FileChooser by delegating to Nautilus
    # — which is not installed in this config, so every download is silently
    # cancelled. Force FileChooser to the gtk backend, which has no Nautilus
    # dependency.
    xdg.portal = {
      enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
      config.common."org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
    };
  };
}
