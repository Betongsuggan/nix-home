{ config, lib, pkgs, ... }:

with lib;

{
  options.games = {
    enable = mkEnableOption "Enable gaming setup";
    
    steamBigPicture = mkOption {
      type = types.bool;
      default = false;
      description = "Auto-start Steam in Big Picture mode";
    };
  };

  config = mkIf config.games.enable {
    # Apply to all users or legacy single user
    home-manager.users = 
      let
        createGameConfig = steamBigPicture: {
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

          # Steam Big Picture autostart service
          systemd.user.services.steam-bigpicture = mkIf steamBigPicture {
            Unit = {
              Description = "Steam Big Picture Mode";
              After = [ "graphical-session.target" ];
              PartOf = [ "graphical-session.target" ];
            };
            
            Service = {
              Type = "simple";
              ExecStart = "${pkgs.steam}/bin/steam -bigpicture";
              Restart = "on-failure";
              RestartSec = "5s";
              Environment = "DISPLAY=:0";
            };
            
            Install = {
              WantedBy = [ "graphical-session.target" ];
            };
          };
        };
      in
      # Apply to legacy user if defined
      (optionalAttrs (config.user != "") {
        ${config.user} = createGameConfig (config.games.steamBigPicture or false);
      }) //
      # Apply to all system users that have games enabled in their homeConfig
      (mapAttrs (name: userData: 
        if (userData.homeConfig.games.enable or false) then 
          createGameConfig (userData.homeConfig.games.steamBigPicture or false)
        else {}
      ) config.systemUsers);

    unfreePackages = [ "discord" "steam" "steam-original" "steam-run" ];
  };
}
