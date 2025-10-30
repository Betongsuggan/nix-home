{ pkgs, inputs, ... }:

{
  home.username = "betongsuggan";
  home.homeDirectory = "/home/betongsuggan";
  home.stateVersion = "25.05";

  imports = [ ../../modules/users inputs.stylix.homeModules.stylix ];

  general.enable = true;
  games.enable = true;
  communication.enable = true;
  development.enable = true;

  terminal = {
    enable = true;
    defaultTerminal = "alacritty";
  };

  starship.enable = true;
  shell = {
    enable = true;
    defaultShell = "bash";
  };

  notifications.enable = true;
  battery-monitor.enable = true;
  thunar.enable = true;
  firefox.enable = true;
  launcher = {
    enable = true;
    backend = "walker";
  };

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

  windowManager = {
    enable = true;
    type = "hyprland";
    monitors = [
      ",3440x1440@100,auto,1"
      "HDMI-A-1,3840x2160@120,auto,2"
      ",preferred,auto,1"
    ];
    autostartApps = {
      firefox = {
        command = "firefox";
        workspace = 1;
      };
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
  git = {
    enable = true;
    userName = "Betongsuggan";
    userEmail = "rydback@gmail.com";
  };
  secrets = {
    enable = true;
    keyProviders = [{
      name = "anthropic_key_provider";
      path = "$HOME/.config/anthropic/key_provider.sh";
      envVarName = "ANTHROPIC_API_KEY";
    }];
  };

  programs.home-manager.enable = true;
}

