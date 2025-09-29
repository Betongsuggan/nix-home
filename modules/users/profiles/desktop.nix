{ lib, config, ... }:

{
  # Full desktop user profile with all productivity and development tools
  
  # Core desktop functionality
  general.enable = true;
  firefox.enable = true;
  
  # Gaming
  games.enable = true;
  game-streaming.enable = lib.mkDefault false; # Can be overridden per user
  
  # Development tools
  development.enable = true;
  neovim.enable = true;
  git.enable = true;
  
  # Communication
  communication.enable = true;
  
  # Terminal and shell
  alacritty.enable = true;
  bash.enable = true;
  starship.enable = true;
  
  # Desktop environment
  hyprland = {
    enable = true;
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
  
  # File management
  thunar.enable = true;
  
  # Notifications and system integration
  dunst.enable = true;
  kanshi.enable = true;
  
  # Theming
  theme = {
    enable = true;
    # Specific theming can be overridden per user
  };
  
  # Walker launcher
  walker = {
    enable = true;
    runAsService = false;
  };
  
  # Hardware-specific (can be disabled for users who don't need it)
  undervolting.enable = lib.mkDefault false;
}