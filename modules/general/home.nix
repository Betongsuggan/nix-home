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

    # The one process monitor (htop and btop went): on AMD/Intel bottom
    # attributes GPU load per process from each process's DRM fdinfo (gpu% =
    # engine time, gmem% = VRAM) and shows GPU memory and temperatures in the
    # widgets.
    programs.bottom = {
      enable = true;
      settings = {
        flags = {
          group_processes = false;
          temperature_type = "c";
        };
        # GPU columns only appear when listed
        processes.columns = [
          "pid"
          "name"
          "cpu%"
          "mem%"
          "gpu%"
          "gmem%"
          "read"
          "write"
          "user"
          "state"
          "time"
        ];
      };
    };

    # CLI tools wanted on every machine, headless ones included
    home.packages = with pkgs; [
      dconf
      coreutils
      pciutils
      exfat
      gnumake
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
