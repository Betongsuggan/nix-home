{ config, lib, pkgs, ... }:

with lib;

let
  hmUsers = config.home-manager.users or {};
  anyUserEnabled = any
    (u: (u.fileManager.enable or false))
    (attrValues hmUsers);
in
{
  config = mkIf anyUserEnabled {
    # Settings backend for Thunar/XFCE applications
    programs.xfconf.enable = true;

    # Thunar file manager with plugins
    programs.thunar = {
      enable = true;
      plugins = with pkgs.xfce; [
        thunar-archive-plugin
        thunar-volman
      ];
    };

    # Virtual filesystem support (trash, MTP, SMB, SFTP, etc.)
    services.gvfs.enable = true;

    # Thumbnail service
    services.tumbler.enable = true;

    # Disk management for auto-mounting
    services.udisks2.enable = true;

    # Polkit for privileged operations (mounting, etc.)
    security.polkit.enable = true;
  };
}
