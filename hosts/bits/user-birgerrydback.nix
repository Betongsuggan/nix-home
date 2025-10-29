{ pkgs, inputs, ... }:

{
  home.username = "birgerrydback";
  home.homeDirectory = "/home/birgerrydback";
  home.stateVersion = "24.05";

  imports = [ ../../modules/users inputs.stylix.homeModules.stylix ];

  general.enable = true;
  development.enable = true;
  qutebrowser.enable = true;
  communication.enable = true;
  games.enable = true;
  battery-monitor.enable = true;
  thunar.enable = true;
  starship.enable = true;

  terminal = {
    enable = true;
    defaultTerminal = "alacritty";
  };

  shell = {
    enable = true;
    defaultShell = "bash";
  };

  notifications.enable = true;

  controls = {
    enable = true;
    brightness.backend = "brightnessctl";
  };

  launcher = {
    enable = true;
    backend = "walker";
  };

  windowManager = {
    enable = true;
    type = "hyprland";
    composeKey = "ralt";
    monitors = [ ",preferred,auto,1" ];
    autostartApps = {
      firefox = {
        command = "firefox";
        workspace = 1;
      };

      slack = {
        command = "slack";
        workspace = 9;
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
    userName = "BirgerRydback";
    userEmail = "birger.rydback@bits.bi";
  };

  secrets = {
    enable = true;
    keyProviders = [
      {
        name = "tavily_key_provider";
        path = "$HOME/.config/tavily/key_provider.sh";
        envVarName = "TAVILY_API_KEY";
      }
      {
        name = "anthropic_key_provider";
        path = "$HOME/.config/anthropic/key_provider.sh";
        envVarName = "ANTHROPIC_API_KEY";
      }
      {
        name = "localstack_key_provider";
        path = "$HOME/.config/localstack/key_provider.sh";
        envVarName = "LOCALSTACK_AUTH_TOKEN";
      }
    ];
  };

  programs.home-manager.enable = true;
}

