{ config, lib, pkgs, ... }:
with lib;

{
  options.dunst = {
    enable = mkEnableOption "Enable Dunst notification daemon";
  };

  config = mkIf config.dunst.enable {
    #home-manager.users.${config.user}.home = {
      services.dunst = {
        enable = true;
        iconTheme.package = pkgs.tela-icon-theme;
      };
    #}; 
  };
}
  
