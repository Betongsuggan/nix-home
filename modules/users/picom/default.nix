{ config, pkgs, lib, ... }:
with lib;

let
  cfg = config.br.picom;
in
{
  options.br.picom = {
    enable = mkEnableOption "Enable Picom service";
  };

  config = mkIf (cfg.enable) {
    services.picom = {
      enable = true;
      backend = "glx";
      fade = true;
      fadeSteps =  [ 0.1 0.12 ];
      vSync = true;
    };
  };
}
