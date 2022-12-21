{ config, lib, pkgs, ... }:
with lib;

let
  cfg = config.br.rofi;
  #theme = import ../theming/theme.nix;
  #config = import ./rofi-config.nix { theme = theme; };
in
{
  options.br.rofi = {
    enable = mkEnableOption "Enable Rofi application launcher";
  };

  config = mkIf (cfg.enable) {
    programs.rofi = {
      enable = true;
      terminal = "urxvt";
      theme = "gruvbox-dark-soft";
    };
  };
}
