{ config, lib, pkgs, ... }:
with lib;

{
  options.general = {
    enable = mkEnableOption "Enable general desktop programs";
  };

  config = mkIf config.general.enable {
    dconf.enable = true;

    # Explicitly set XDG_DATA_HOME to fix Ghostty cursor size bug
    # (fontconfig behaves differently when this is not explicitly set)
    home.sessionVariables = {
      XDG_DATA_HOME = "$HOME/.local/share";
    };

    home.packages = with pkgs; [
      dconf
      btop
      coreutils
      pciutils
      kazam
      exfat
      gimp
      gedit
      gnumake
      gparted
      gthumb
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
