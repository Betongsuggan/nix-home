{ config, lib, pkgs, ... }:
with lib;

{
  options.kde = {
    enable = mkEnableOption "Enable KDE desktop environment";
  };

  config = mkIf config.kde.enable {
    services.gvfs.enable = true;
    services.xserver = {
      enable = true;

      displayManager.sddm.enable = true;
      desktopManager.plasma5.enable = true;
    };
  };
}
