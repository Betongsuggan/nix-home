{ config, lib, pkgs, ... }:
with lib;

let
  cfg = config.br.general;
in {
  options.br.general = {
    enable = mkEnableOption "Enable general desktop programs";
  };

  config = mkIf (cfg.enable) {
    home.packages = with pkgs; [
      bpytop
      kazam    
      etcher
      exfat
      gimp        
      gnome.gedit
      gparted     
      gthumb 
      htop    
      kdenlive
      okular  
      p7zip     
      lm_sensors
      p7zip     
      unzip          
      yubikey-manager
      xfce.thunar            
      xfce.thunar-volman     
      gvfs
      polkit
      udisks
      vlc
    ];
  };
}
