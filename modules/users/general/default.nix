{ config, lib, pkgs, ... }:
with lib;

let
  cfg = config.br.general;
in {
  options.br.general = {
    enable = mkEnableOption "Enable general desktop programs";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      bpytop
      coreutils
      kazam
      etcher
      exfat
      gimp
      gnome.gedit
      gparted
      gthumb
      gvfs
      htop
      iio-sensor-proxy
      kdenlive
      lm_sensors
      okular
      p7zip
      polkit
      powertop
      ryzenadj
      unzip
      yubikey-manager
      xfce.thunar
      xfce.thunar-volman
      udisks
      usbutils
      vlc
    ];
  };
}
