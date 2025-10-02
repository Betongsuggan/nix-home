{ config, pkgs, ... }:

{
  home.username = "gamer";
  home.homeDirectory = "/home/gamer";
  home.stateVersion = "25.05";

  home.packages = with pkgs; [
    # Core Steam setup
    steam
    steam-run
    
    # Gaming utilities
    gamescope
    mangohud
    gamemode
    
    # Performance monitoring
    htop
    
    # Audio support
    pulseaudio
    pavucontrol
    
    # Basic utilities
    xdg-utils
  ];

  # Auto-start Steam Big Picture Mode on login
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

  # Gaming environment variables
  home.sessionVariables = {
    MANGOHUD = "1";
    MANGOHUD_DLSYM = "1";
    DXVK_HUD = "fps";
    STEAM_FRAME_FORCE_CLOSE = "1";
    # Enable FSR for compatible games
    WINE_FULLSCREEN_FSR = "1";
    # Optimize Steam overlay
    STEAM_DISABLE_OVERLAY_DWM = "1";
  };


  # XDG directory configuration
  #xdg = {
  #  mimeApps.enable = true;
  #  userDirs = {
  #    enable = true;
  #    createDirectories = true;
  #    documents = "$HOME/documents";
  #    download = "$HOME/downloads";
  #    music = "$HOME/media/music";
  #    pictures = "$HOME/media/images";
  #    videos = "$HOME/media/videos";
  #    desktop = "$HOME/other/desktop";
  #    publicShare = "$HOME/other/public";
  #    templates = "$HOME/other/templates";
  #    extraConfig = { XDG_DEV_DIR = "$HOME/dev"; };
  #  };
  #};

  programs.home-manager.enable = true;
}

