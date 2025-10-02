{ config, lib, pkgs, ... }:
with lib;

{
  options.general = {
    enable = mkEnableOption "Enable general desktop programs";
  };

  config = mkIf config.general.enable {
    home.packages = with pkgs; [
      btop
      coreutils
      pciutils
      kazam
      exfat
      gimp
      gedit
      gparted
      gthumb
      gvfs
      htop
      iio-sensor-proxy
      imv
      kooha
      lf
      lm_sensors
      lshw
      kdePackages.okular
      p7zip
      powertop
      ryzenadj
      silver-searcher
      unzip
      yubikey-manager
      udisks
      usbutils
      vlc
      wine
      zip
    ];
  };
}
