{ config, lib, pkgs, ...}:
with lib;

let
  cfg = config.br.fonts;
in {
  options.br.fonts = {
    enable = mkEnableOption "Enable additional fonts";
  };

  config = mkIf cfg.enable {
    fonts.fontconfig.enable = true;
    home.packages = with pkgs; [ glibcLocales nerdfonts noto-fonts-emoji ];
  };
}
  
