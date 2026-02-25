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
    backend = "alacritty";
  };

  starship.enable = true;
  shell = {
    enable = true;
    backend = "bash";
  };

  notifications.enable = true;
  battery-monitor.enable = true;
  fileManager = {
    enable = true;
    backend = "thunar";
  };
  firefox.enable = true;
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
    backend = "hyprland";
    monitors = [
      "DP-2,3440x1440@240,auto,1,bitdepth,10"
      "HDMI-A-1,disable"
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

