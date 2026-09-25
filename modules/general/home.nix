{
  config,
  lib,
  pkgs,
  ...
}:
with lib;

{
  options.my.general = {
    enable = mkEnableOption "the everyday CLI toolset";
  };

  config = mkIf config.my.general.enable {
    dconf.enable = true;

    home.sessionVariables = {
      XDG_DATA_HOME = "$HOME/.local/share";
    };

    # CLI tools wanted on every machine, headless ones included
    home.packages = with pkgs; [
      dconf
      btop
      coreutils
      pciutils
      exfat
      gnumake
      htop
      jq
      lf
      lm_sensors
      lshw
      ls-lint
      openssl
      p7zip
      powertop
      silver-searcher
      unzip
      yubikey-manager
      usbutils
      zip
    ];
  };
}
