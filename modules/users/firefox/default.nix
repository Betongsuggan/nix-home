{ config, lib, pkgs, ... }:
with lib;

{
  options.firefox = {
    enable = mkEnableOption "Enable Firefox browser for user";
  };

  config = mkIf config.firefox.enable {
    home-manager.users.${config.user} = {
      home.sessionVariables = {
        MOZ_X11_EGL = "1";
        LIBVA_DRIVER_NAME = "i965";
      };
      programs.firefox = {
        enable = true;
        profiles.betongsuggan = {
          settings = {
            "media.ffmpeg.vaapi.enabled" = true;
            "media.ffvpx.enabled" = false;
            "media.av1.enabled" = false;
            "gfx.webrender.all" = true;
          };
        };
      };
    };
  };
}