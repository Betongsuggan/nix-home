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

  config = mkIf config.tunar.enable {
    programs.thunar.enable = true;
    programs.xfconf.enable = true;

    services.gvfs.enable = true; # Mount, trash, and other functionalities
    services.tumbler.enable = true; # Thumbnail support for images
  };
}
