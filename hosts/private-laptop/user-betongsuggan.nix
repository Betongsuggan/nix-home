{ pkgs, ... }: {
  home = {
    username = "betongsuggan";
    homeDirectory = "/home/betongsuggan";
    stateVersion = "24.05";
  };

  imports = [ ../../modules/users ];

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
