{ config, lib, pkgs, ... }:
with lib;

let
  cfg = config.br.sway;
in {
  options.br.sway = {
    enable = mkEnableOption "Enable Sway";

  };

  config = mkIf cfg.enable {
    wayland.windowManager.sway = {
      enable = true;
      config = rec {
        modifier = "Mod4";
      };
    };
  };
}
