{ config, lib, pkgs, ... }:
with lib;

{
  options.general = {
    enable = mkEnableOption "Enable general desktop programs";
  };

  config = mkIf config.general.enable {
    home-manager.users.${config.user}.home.packages = with pkgs; [
      btop
      coreutils
      pciutils
      kazam
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
      lshw
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
