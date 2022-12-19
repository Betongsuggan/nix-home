{ config, lib, pkgs, ... }:
with lib;

let
  cfg = config.br.power-management;
in {
  options.br.power-management = {
    enable = mkEnableOption "Enable power management";
  };

  config = mkIf cfg.enable {
    services.tlp.enable = true;
  };
}
