{ config, lib, pkgs, ... }:
with lib;

let
  cfg = config.br.communication;
in {
  options.br.communication = {
    enable = mkEnableOption "Enable communication tooling";
  };

  config = mkIf (cfg.enable) {
    home.packages = with pkgs; [
      slack
      teams
      #zoom-us
      skypeforlinux
    ];
  };
}

