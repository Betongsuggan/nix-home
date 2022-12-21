{ config, lib, pkgs, ... }:
with lib;

let
  cfg = config.br.games;
in {
  options.br.games = {
    enable = mkEnableOption "Enable gaming setup";
  };

  config = mkIf (cfg.enable) {
    home.packages = with pkgs; [
      steam
      retroarch
      lutris
      chiaki
      antimicroX
      mangohud
      discord
    ];
  };
}
