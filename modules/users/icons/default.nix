{ config, lib, pkgs, ... }:
with lib;

{
  options.icons = {
    enable = mkEnableOption "Set Tela icon set";
  };

  config = mkIf config.icons.enable {
    home-manager.users.${config.user}.home.packages = [
      pkgs.tela-icon-theme
      #(
      #  home.packages.iconTheme.override {
      #    # Specify the path to your custom icon theme
      #    theme = pkgs.tela-icon-theme;
      #  }
      #)
    ];
  };
}
  
