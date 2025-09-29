{ pkgs, config, ... }:

{
  # System-level user configuration only
  
  # Primary user (existing configuration)
  user = "betongsuggan";
  fullName = "Birger Rydback";
  extraUserGroups = [ "wheel" "networkmanager" "network" "video" "docker" "uinput" ];
  
  # Additional gaming user (no sudo access)
  users.users.gamer = {
    isNormalUser = true;
    description = "Gaming User";
    extraGroups = [ "networkmanager" "video" ];
    hashedPassword = "";
  };
  
  # Enable autologin for gaming user
  autologin = {
    enable = true;
    user = "gamer";
  };
  
  # Home-manager configurations
  home-manager.users.gamer = { pkgs, ... }: {
    home.stateVersion = "25.05";
    home.packages = [ pkgs.home-manager pkgs.steam ];
    programs.home-manager.enable = true;
    
    # Minimal gaming configuration with Steam autostart
    systemd.user.services.steam-bigpicture = {
      Unit = {
        Description = "Steam Big Picture Mode";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.steam}/bin/steam -bigpicture";
        Restart = "on-failure";
        RestartSec = "5s";
        Environment = "DISPLAY=:0";
      };
      
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
    
    xdg = {
      mimeApps.enable = true;
      userDirs = {
        enable = true;
        createDirectories = true;
        documents = "$HOME/documents";
        download = "$HOME/downloads";
        music = "$HOME/media/music";
        pictures = "$HOME/media/images";
        videos = "$HOME/media/videos";
        desktop = "$HOME/other/desktop";
        publicShare = "$HOME/other/public";
        templates = "$HOME/other/templates";
        extraConfig = { XDG_DEV_DIR = "$HOME/dev"; };
      };
    };
  };
  
  # User module configurations for betongsuggan
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
    runAsService = false;
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
  undervolting.enable = true;
}