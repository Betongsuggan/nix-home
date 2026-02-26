{ pkgs, inputs, ... }:
{
  home = {
    username = "betongsuggan";
    homeDirectory = "/home/betongsuggan";
    stateVersion = "24.05";
  };

  imports = [
    ../../modules/users
    inputs.stylix.homeModules.stylix
  ];

  general.enable = true;
  firefox.enable = true;
  games.enable = true;
  communication.enable = true;
  starship.enable = true;
  notifications.enable = true;
  battery-monitor.enable = true;
  kanshi.enable = true;
  development.enable = true;
  fileManager = {
    enable = true;
    backend = "thunar";
  };

  shell = {
    enable = true;
    backend = "bash";
  };

  terminal = {
    enable = true;
    backend = "ghostty";
    colors.useTheme = true;
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
    backend = "hyprland";
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
