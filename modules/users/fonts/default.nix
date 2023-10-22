{ config, lib, pkgs, ... }:
with lib;

{
  options.fonts = {
    enable = mkEnableOption "Enable additional fonts";
  };

  config = mkIf config.fonts.enable {
    fonts.fontconfig.enable = true;
    home-manager.users.${config.user}.home.packages = with pkgs; [ glibcLocales nerdfonts noto-fonts-emoji ];
  };
}
  
