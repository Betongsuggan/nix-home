{ pkgs, inputs, ... }:

{
  home.username = "birgerrydback";
  home.homeDirectory = "/home/birgerrydback";
  home.stateVersion = "24.05";

  imports = [
    ../../modules/users
    inputs.walker.homeManagerModules.default
    inputs.stylix.homeModules.stylix
  ];

  # Home-manager module configurations
  general.enable = true;
  qutebrowser.enable = true;
  games.enable = true;
  flatpak.enable = true;
  communication.enable = true;
  neovim.enable = true;
  alacritty.enable = true;
  bash.enable = true;
  nushell.enable = true;
  fish.enable = true;
  starship.enable = true;
  dunst.enable = true;
  kanshi.enable = true;
  thunar.enable = true;
  walker.enable = true;
  development.enable = true;

  hyprland = {
    enable = true;
    monitorResolutions = [ "1,3840x2560@60,auto,1" ",preferred,auto,1" ];
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

