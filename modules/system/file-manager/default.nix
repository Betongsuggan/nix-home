{ config, lib, pkgs, ... }:
with lib;

{
  options.fileManagerSystem = {
    enable = mkEnableOption "file manager system services";

    enableGvfs = mkOption {
      type = types.bool;
      default = true;
      description = "Enable GVFS for virtual filesystem support (trash, MTP, SMB, SFTP)";
    };

    enableTumbler = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Tumbler thumbnail service";
    };

    enableUdisks = mkOption {
      type = types.bool;
      default = true;
      description = "Enable udisks2 for disk management and auto-mounting";
    };
  };

  config = mkIf config.fileManagerSystem.enable {
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
    services.gvfs.enable = config.fileManagerSystem.enableGvfs;

    # Thumbnail service
    services.tumbler.enable = config.fileManagerSystem.enableTumbler;

    # Disk management for auto-mounting
    services.udisks2.enable = config.fileManagerSystem.enableUdisks;

    # Polkit for privileged operations (mounting, etc.)
    security.polkit.enable = true;
  };
}