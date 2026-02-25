{ pkgs, inputs, ... }:

{
  imports = [ ../../modules/users inputs.stylix.homeModules.stylix ];

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

  general.enable = true;
  firefox.enable = true;
  fileManager = {
    enable = true;
    backend = "thunar";
  };

  communication.enable = true;
  starship.enable = true;
  terminal = {
    enable = true;
    backend = "alacritty";
  };

  launcher = {
    enable = true;
    backend = "vicinae";
    vicinae = {
      extensions = with pkgs; [
        vicinae-wifi-commander
        vicinae-bluetooth
        vicinae-monitor
      ];
    };
  };

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

  # Enable Hyprland for gaming session
  # Steam Big Picture is managed by Sunshine when streaming clients connect
  hyprland.lockscreen.enable = false; # Gaming user doesn't need lockscreen

  windowManager = {
    enable = true;
    backend = "hyprland";
    monitors = [
      "SUNSHINE,1920x1080@120,auto,1,vrr,1,bitdepth,10"
      "DP-2,3440x1440@240,auto,1,vrr,1,bitdepth,10"
      "HDMI-A-1,3840x2160@120,auto,2,vrr,1,bitdepth,10"
      ",preferred,auto,1"
    ];

    # Virtual monitor for headless streaming
    virtualMonitors = [ "SUNSHINE" ];

    autostartApps = {
      steam = {
        command = "steam -bigpicture";
        workspace = 1;
      };
    };
  };

  shell = {
    enable = true;
    backend = "bash";
  };

  theme = {
    enable = true;
    wallpaper = ../../assets/wallpaper/zeal.jpg;
    cursor = {
      package = pkgs.banana-cursor;
      name = "Banana";
    };
  };

  git = {
    enable = true;
    userName = "Betongsuggan";
    userEmail = "rydback@gmail.com";
  };

  programs.console-mode = {
    enable = true;

    autoStart = false;

    gamescopeBin = "${pkgs.unstable.gamescope}/bin/gamescope";
    steamBin = "${pkgs.steam}/bin/steam";
    steamArgs =
      [ "-steamos3" ]; # Enable Steam Deck features (Bluetooth management, etc.)

    # Display settings auto-detected from EDID
    # Uncomment to override:
    # display = "card1-HDMI-A-1";
    # resolution = "2560x1440";
    # refreshRate = 144;
    # forceVrr = true;
    # forceHdr = true;

    environmentVariables = {
      RADV_PERFTEST = "gpl";
      MESA_VK_WSI_PRESENT_MODE = "mailbox";
      STEAM_USE_DYNAMIC_VRS = "0";
      SDL_JOYSTICK_HIDAPI = "0";
    };

    createDesktopEntry = true;
    desktopEntry = {
      name = "Gamescope Gaming Session";
      genericName = "Steam Big Picture (Gamescope)";
      comment = "Launch Steam Big Picture in Gamescope session";
      icon = "steam";
      categories = [ "Game" "Application" ];
    };
  };

  home.packages = with pkgs;
    let gamescopeUnstable = unstable.gamescope;
    in [
      steam
      steam-run
      htop
      pulseaudio
      pavucontrol
      xdg-utils
      edid-decode
      gamescopeUnstable
    ];

  programs.bash = {
    enable = true;
    profileExtra = ''
      # Set XDG_VTNR if not already set
      if [[ -z "$XDG_VTNR" ]]; then
        TTY=$(tty)
        case "$TTY" in
          /dev/tty[0-9]*)
            export XDG_VTNR="''${TTY##*/tty}"
            ;;
        esac
      fi

      # Launch Hyprland on TTY1 (if not already in a graphical session)
      # Hyprland auto-starts Steam Big Picture and Sunshine
      if [[ "$XDG_VTNR" = "1" && -z "$WAYLAND_DISPLAY" ]]; then
        exec Hyprland
      fi
    '';
  };

  # Session variables are now set by console-mode's environmentVariables
  # They're kept here for consistency and system-wide availability
  home.sessionVariables = {
    # MangoHud variables are now handled by the games module
    # DXVK_HUD = "fps";  # Might conflict with MangoHud
    # AMD GPU optimizations
    RADV_PERFTEST = "gpl";
    MESA_VK_WSI_PRESENT_MODE = "mailbox";
    # Controller and overlay fixes
    STEAM_USE_DYNAMIC_VRS = "0";
    SDL_JOYSTICK_HIDAPI = "0";
    #STEAM_FRAME_FORCE_CLOSE = "1";
    # Enable FSR for compatible games
    #WINE_FULLSCREEN_FSR = "1";
    # Optimize Steam overlay - keep disabled for AMD
    #STEAM_DISABLE_OVERLAY_DWM = "1";
  };

  programs.home-manager.enable = true;
}

