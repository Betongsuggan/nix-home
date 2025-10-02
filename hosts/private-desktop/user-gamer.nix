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
        
        # Ensure input devices are accessible to gamescope
        export LIBINPUT_QUIRKS_DIR=/usr/share/libinput
        export XDG_SESSION_TYPE=tty
        
        # Let Steam Input handle controller detection and hot-plugging
        # No hardcoded device paths - Steam will auto-detect controllers
        
        # Get native resolution from framebuffer
        RESOLUTION=$(${pkgs.coreutils}/bin/cat /sys/class/drm/card*/modes 2>/dev/null | ${pkgs.coreutils}/bin/head -1 || echo "1920x1080")
        WIDTH=$(echo $RESOLUTION | ${pkgs.coreutils}/bin/cut -d'x' -f1)
        HEIGHT=$(echo $RESOLUTION | ${pkgs.coreutils}/bin/cut -d'x' -f2)
        
        # Fallback to 1920x1080 if detection fails
        WIDTH=''${WIDTH:-1920}
        HEIGHT=''${HEIGHT:-1080}
        
        exec ${pkgs.gamescope}/bin/gamescope -W $WIDTH -H $HEIGHT -f -e -- ${pkgs.steam}/bin/steam -bigpicture
      fi
    '';
  };

  home.sessionVariables = {
    MANGOHUD = "1";
    MANGOHUD_DLSYM = "1";
    DXVK_HUD = "fps";
    # AMD GPU optimizations for gamescope
    RADV_PERFTEST = "gpl";
    MESA_VK_WSI_PRESENT_MODE = "mailbox";
    # Controller and overlay fixes
    STEAM_USE_DYNAMIC_VRS = "0";
    # Force SDL to use evdev backend for better compatibility
    SDL_JOYSTICK_HIDAPI = "0";
    #STEAM_FRAME_FORCE_CLOSE = "1";
    # Enable FSR for compatible games
    #WINE_FULLSCREEN_FSR = "1";
    # Optimize Steam overlay - keep disabled for AMD
    #STEAM_DISABLE_OVERLAY_DWM = "1";
  };

  programs.home-manager.enable = true;
}

