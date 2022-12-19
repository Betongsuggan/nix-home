{ config, lib, pkgs, ... }:
with lib;

let
  cfg = config.br.docker;
in {
  options.br.docker = {
    enable = mkEnableOption "Enable Docker";
  };

  config = mkIf cfg.enable {
    virtualisation.docker.enable = true;
  };
}
