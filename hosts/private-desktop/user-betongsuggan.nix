{ pkgs, ... }:

{
  home.username = "betongsuggan";
  home.homeDirectory = "/home/betongsuggan";
  home.stateVersion = "25.05";

  home.packages = with pkgs; [ ];

  imports = [ ../../modules/users ];

  general.enable = true;
  games.enable = true;
  communication.enable = true;
  development.enable = true;
  neovim.enable = true;
  alacritty.enable = true;
  starship.enable = true;
  bash.enable = true;
  dunst.enable = true;
  kanshi.enable = true;
  thunar.enable = true;
  firefox.enable = true;
  walker = {
    enable = true;
    runAsService = true;
  };
  hyprland = {
    enable = true;
    monitorResolutions = [
      ",3440x1440@100,auto,1"
      "HDMI-A-1,3840x2160@120,auto,2"
      ",preferred,auto,1"
    ];
    autostartApps = {
      firefox = {
        command = "firefox";
        workspace = 1;
      };
      steam = {
        command = "steam";
        workspace = 2;
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

