{ config, lib, pkgs, ... }:
with lib;

let
  cfg = config.br.wayland;
in {
  options.br.wayland = {
    enable = mkEnableOption "Wayland setup";
  };

  config = mkIf cfg.enable {
    security.polkit.enable = true;
    programs.light.enable = true;

    security.pam.services.swaylock = {
      text = "auth include login";
    };
  };
}
