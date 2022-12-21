{ config, lib, pkgs, ... }:
with lib;

let
  cfg = config.br.audio;
in {
  options.br.audio = {
    enable = mkEnableOption "Enable user audio programs";
  };

  config = mkIf (cfg.enable) {
    home.packages = [ pkgs.pavucontrol ];
  };
}
