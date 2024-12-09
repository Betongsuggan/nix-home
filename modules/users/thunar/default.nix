{ pkgs, config, lib, ... }:
with lib;
{
  options.thunar = {
    enable = mkOption {
      description = "Enable Thunar file explorer";
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.thunar.enable {
    programs.xfconf.enable = true;

    programs.thunar = {
      enable = true;
      plugins = with pkgs.xfce; [
        thunar-archive-plugin
        thunar-volman
      ];
    };

    services.gvfs.enable = true; # Mount, trash, and other functionalities
    services.tumbler.enable = true; # Thumbnail support for images
  };
}
