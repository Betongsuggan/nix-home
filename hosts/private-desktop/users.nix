{ pkgs, ... }:

{
  # User configurations for private-desktop

  systemUsers = {
    betongsuggan = {
      username = "betongsuggan";
      fullName = "Birger Rydback";
      extraGroups =
        [ "wheel" "networkmanager" "network" "video" "docker" "uinput" ];
      autologin = false;
      homeConfig = {
        # Use desktop profile as base
        userProfile = "desktop";

        # User-specific overrides and additions
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

        game-streaming.server.enable = true;
        undervolting.enable = true;

        theme = {
          enable = true;
          wallpaper = ../../assets/wallpaper/zeal.jpg;
          cursor = {
            package = pkgs.banana-cursor;
            name = "Banana";
          };
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
      };
    };

    gamer = {
      username = "gamer";
      fullName = "Gaming User";
      extraGroups = [ "wheel" "networkmanager" "video" ];
      autologin = true;
      homeConfig = {
        # Use minimal gaming profile - no window manager, just Steam Big Picture
        userProfile = "minimal-gaming";

        # Gaming-specific configuration
        games = {
          enable = true;
          steamBigPicture = true;
        };

        theme = {
          enable = true;
          wallpaper = ../../assets/wallpaper/nix-background.png;
          cursor = {
            package = pkgs.banana-cursor;
            name = "Banana";
          };
        };

        # No window manager - Steam Big Picture runs directly on display manager
        # This reduces resource usage and gives Steam full control
      };
    };
  };
}

