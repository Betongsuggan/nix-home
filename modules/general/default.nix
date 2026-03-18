{
  config,
  lib,
  pkgs,
  ...
}:
with lib;

{
  options.general = {
    enable = mkEnableOption "Enable general desktop programs";
  };

  config = mkIf config.general.enable {
    dconf.enable = true;

    home.sessionVariables = {
      XDG_DATA_HOME = "$HOME/.local/share";
    };

    home.packages = with pkgs; [
      dconf
      btop
      coreutils
      pciutils
      exfat
      gimp
      gedit
      gnumake
      gparted
      gvfs
      htop
      iio-sensor-proxy
      imv
      jq
      kdePackages.okular
      wf-recorder
      lf
      lm_sensors
      lshw
      ls-lint
      openssl
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
