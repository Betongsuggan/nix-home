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

  battery-monitor.enable = true;

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

  windowManager = {
    enable = true;
    type = "hyprland";
    autostartApps = {
      console-mode = {
        command = ''console-mode --launcher "walker -d"'';
        workspace = 1;
      };
    };
  };

  shell = {
    enable = true;
    defaultShell = "bash";
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

  # Bash is enabled automatically by console-mode's autoStart option
  programs.bash = {
    enable = true;
    # Set XDG_VTNR if not already set (for console-mode autoStart to work)
    profileExtra = ''
      if [[ -z "$XDG_VTNR" ]]; then
        # Extract VT number from tty
        TTY=$(tty)
        case "$TTY" in
          /dev/tty[0-9]*)
            export XDG_VTNR="''${TTY##*/tty}"
            ;;
        esac
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

