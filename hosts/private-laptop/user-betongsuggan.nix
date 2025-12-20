{ pkgs, inputs, ... }: {
  home = {
    username = "betongsuggan";
    homeDirectory = "/home/betongsuggan";
    stateVersion = "24.05";
  };

  imports = [ ../../modules/users inputs.stylix.homeModules.stylix ];

  general.enable = true;
  firefox.enable = true;
  games.enable = true;
  communication.enable = true;
  starship.enable = true;
  notifications.enable = true;
  battery-monitor.enable = true;
  kanshi.enable = true;
  development.enable = true;
  thunar.enable = true;

  shell = {
    enable = true;
    defaultShell = "bash";
  };

  terminal = {
    enable = true;
    defaultTerminal = "alacritty";
  };

  launcher = {
    enable = true;
    backend = "walker";
  };

  theme = {
    enable = true;
    wallpaper = ../../assets/wallpaper/zeal.jpg;
    cursor = {
      package = pkgs.banana-cursor;
      name = "Banana";
    };
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

  windowManager = {
    enable = true;
    type = "hyprland";
    autostartApps = {
      firefox = {
        command = "firefox";
        workspace = 1;
      };

      auto-screen-rotation = {
        command = "auto-screen-rotation";
        workspace = null;
      };

      touchegg = {
        command = "${pkgs.touchegg}/bin/touchegg";
        workspace = null;
      };
    };
  };

  git = {
    enable = true;
    userName = "Betongsuggan";
    userEmail = "rydback@gmail.com";
  };

  secrets = {
    enable = true;
    keyProviders = [
      {
        name = "anthropic_key_provider";
        path = "$HOME/.config/anthropic/key_provider.sh";
        envVarName = "ANTHROPIC_API_KEY";
      }
      {
        name = "tavily_key_provider";
        path = "$HOME/.config/tavily/key_provider.sh";
        envVarName = "TAVILY_API_KEY";
      }
    ];
  };

  programs.home-manager.enable = true;
}
