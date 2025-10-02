{ pkgs, ... }:

{
  home.username = "gamer";
  home.homeDirectory = "/home/gamer";
  home.stateVersion = "25.05";

  home.packages = with pkgs; [
    steam
    steam-run

    gamescope
    mangohud
    gamemode

    htop

    pulseaudio
    pavucontrol

    xdg-utils
  ];

  programs.bash = {
    enable = true;
    profileExtra = ''
      # Auto-start Steam Big Picture Mode if not already running and on main console
      if [[ -z "$DISPLAY" && "$XDG_VTNR" = "1" ]]; then
        export MANGOHUD=1
        export STEAM_FORCE_DESKTOPUI_SCALING=1
        exec ${pkgs.gamescope}/bin/gamescope -W 1920 -H 1080 -f -- ${pkgs.steam}/bin/steam -bigpicture
      fi
    '';
  };

  home.sessionVariables = {
    MANGOHUD = "1";
    MANGOHUD_DLSYM = "1";
    DXVK_HUD = "fps";
    #STEAM_FRAME_FORCE_CLOSE = "1";
    # Enable FSR for compatible games
    #WINE_FULLSCREEN_FSR = "1";
    # Optimize Steam overlay
    #STEAM_DISABLE_OVERLAY_DWM = "1";
  };

  programs.home-manager.enable = true;
}

