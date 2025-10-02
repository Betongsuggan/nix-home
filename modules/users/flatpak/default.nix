{ pkgs, config, lib, ... }:
with lib;

{
  options.flatpak = {
    enable = mkOption {
      description = "Enable Flatpak";
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.flatpak.enable {
    home.sessionVariables = {
      XDG_DATA_DIRS="$XDG_DATA_DIRS:/usr/share:/var/lib/flatpak/exports/share:$HOME/.local/share/flatpak/exports/share";
    };
  };
}
