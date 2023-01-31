{ config, lib, pkgs, ... }:
with lib;

let
  cfg = config.br.kde;
in {
  options.br.kde = {
    enable = mkEnableOption "Enable KDE desktop environment";
  };

  config = mkIf cfg.enable {
    services.gvfs.enable = true;
    services.xserver = {
      enable = true;

      displayManager.sddm.enable = true;
      desktopManager.plasma5.enable = true;
    };
  };
}
