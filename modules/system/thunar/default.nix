{ config, lib, pkgs, ... }:
with lib;

{
  options.thunarSystem = {
    enable = mkEnableOption "Enable Thunar system services";
  };

  config = mkIf config.thunarSystem.enable {
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