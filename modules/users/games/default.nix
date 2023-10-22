{ config, lib, pkgs, ... }:
with lib;

{
  options.games = {
    enable = mkEnableOption "Enable gaming setup";
  };

  config = mkIf config.games.enable {
    home-manager.users.${config.user}.packages = with pkgs; [
      antimicroX
      chiaki
      discord
      evtest
      gamescope
      gamemode
      lutris
      mangohud
      retroarch
      steam
      steam-run
      steamcontroller
      xboxdrv
    ];
  };
}
