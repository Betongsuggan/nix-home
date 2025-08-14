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
        settings = import ./mangohud-settings.nix { };
      };

      home.packages = with pkgs; [
        chiaki
        discord
        #unstable.emulationstation-de
        hello
        libretro.snes9x
        evtest
        gamescope
        gamemode
        lutris
        # Standard RetroArch is still included if you want to use it separately
        #retroarch
        steam
        steam-run
        steamcontroller
      ];
    };

    unfreePackages = [ "discord" "steam" "steam-original" "steam-run" ];
  };
}
