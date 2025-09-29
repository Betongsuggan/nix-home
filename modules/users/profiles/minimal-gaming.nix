# Minimal gaming profile configuration
{
  # Minimal gaming profile - just Steam Big Picture, no window manager
  # Steam will take over the entire display
  
  # Essential system tools only
  general.enable = true;
  
  # Gaming packages and Steam Big Picture autostart
  games = {
    enable = true;
    steamBigPicture = true;
  };
  
  # Very minimal theming
  theme = {
    enable = true;
    # Use default wallpaper (won't be visible anyway with Steam Big Picture)
  };
  
  # Essential terminal access (for troubleshooting)
  bash.enable = true;
  
  # No window manager - Steam Big Picture will run directly on X11/Wayland
  # This means Steam will have full control of the display
}