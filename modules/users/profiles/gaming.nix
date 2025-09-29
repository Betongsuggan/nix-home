{ lib, config, ... }:

{
  # Gaming-focused user profile with minimal desktop and Steam Big Picture
  
  # Essential system tools
  general.enable = true;
  
  # Gaming packages and configuration
  games = {
    enable = true;
    steamBigPicture = true;
  };
  
  # Minimal theming for gaming
  theme = {
    enable = true;
    # Use default wallpaper and cursor
  };
  
  # Hyprland with gaming-optimized settings
  hyprland = {
    enable = true;
    # Gaming user gets minimal window management
    autostartApps = {
      steam = {
        command = "steam -bigpicture";
        workspace = 1;
      };
    };
  };
  
  # Essential terminal and shell
  bash.enable = true;
  starship.enable = true;
  
  # Basic file management
  thunar.enable = true;
  
  # Audio support for games
  # Audio is handled at system level, no user config needed
}