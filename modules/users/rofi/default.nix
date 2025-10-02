{ config, lib, pkgs, ... }:
with lib;

{
  options.rofi = {
    enable = mkEnableOption "Enable Rofi application launcher";
  };

  config = mkIf (config.rofi.enable) {
    programs.rofi = {
      enable = true;
      terminal = "urxvt";
      theme = "gruvbox-dark-soft";
    };
  };
}
