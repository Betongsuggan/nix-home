{ config, lib, pkgs, ... }:

with lib;

{
  options.games = {
    enable = mkEnableOption "Enable gaming setup";
  };

  config = mkIf config.games.enable {
    home-manager.users.${config.user} = {
      programs.mangohud = {
        enable = true;
        enableSessionWide = true;
        settings = import ./mangohud-settings.nix {};
      };

      home.packages = with pkgs; [
        chiaki
        discord
        evtest
        gamescope
        gamemode
        lutris
        retroarch
        steam
        steam-run
        steamcontroller
      ];
    };

    unfreePackages = [ "discord" "steam" "steam-original" "steam-run" ];
  };
}
