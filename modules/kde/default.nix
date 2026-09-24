{
  config,
  lib,
  pkgs,
  ...
}:
with lib;

{
  options.kde = {
    enable = mkEnableOption "Enable KDE desktop environment";
  };

  config = mkIf config.kde.enable {
    services.gvfs.enable = true;
    services.displayManager.sddm = {
      enable = true;
      wayland.enable = true;
    };
    services.desktopManager.plasma6.enable = true;
  };
}
