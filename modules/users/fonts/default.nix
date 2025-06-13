{ config, lib, pkgs, ... }:
with lib;

{
  options.fonts = {
    enable = mkEnableOption "Enable additional fonts";
  };

  config = mkIf config.fonts.enable {
    fonts.fontconfig = {
      enable = true;
         defaultFonts = {
           #sansSerif = [ "Comic Relief" ];
           #monospace = [ "Comic Relief" ];
           monospace = [ "Hasklug Nerd Font Mono" "Noto Color Emoji" ];
         };
    };
    home-manager.users.${config.user}.home = {
      packages = with pkgs; [ glibcLocales comic-relief nerd-fonts.hasklug noto-fonts-emoji ];
    };
  };
}
  
