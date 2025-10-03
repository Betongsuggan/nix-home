{ pkgs, inputs, ... }:

{
  imports = [
    ../../modules/users
    inputs.walker.homeManagerModules.default # Required for walker module consistency
    inputs.stylix.homeModules.stylix
  ];

  home.username = "gamer";
  home.homeDirectory = "/home/gamer";
  home.stateVersion = "25.05";

  # Enable gaming setup with enhanced MangoHud
  games = {
    enable = true;
    mangohud = {
      enable = true;
      detailedMode = true;
      controllerToggle = false; # Now handled by controller module
      position = "top-left";
      fontSize = 22;
    };
  };

  # Disable walker for gaming user
  walker.enable = false;

  # Enable PS5 controller support with MangoHud toggle
  controller = {
    enable = true;
    type = "ps5";
    mangohudToggle = {
      enable = true;
      buttons = [ "square" "triangle" ]; # Press Square or Triangle to toggle
      autoStart = true;
    };
    rumble.enable = true;
  };

  hyprland.enable = true;
  bash.enable = true;
  theme = {
    enable = true;
    wallpaper = ../../assets/wallpaper/zeal.jpg;
    cursor = {
      package = pkgs.banana-cursor;
      name = "Banana";
    };
  };

  home.packages = with pkgs; [ htop pulseaudio pavucontrol xdg-utils ];

  programs.bash = {
    enable = true;
    profileExtra = ''
      # Auto-start Steam Big Picture Mode if not already running and on main console
      if [[ -z "$DISPLAY" && "$XDG_VTNR" = "1" ]]; then
        # MANGOHUD is now handled by the games module
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
    # MangoHud variables are now handled by the games module
    # DXVK_HUD = "fps";  # Might conflict with MangoHud
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

