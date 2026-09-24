{
  config,
  lib,
  pkgs,
  ...
}:
with lib;

{
  options.xserver = {
    enable = mkEnableOption "Enable X server";

    displayManager = mkOption {
      description = "Display manager to use";
      type = types.enum [
        "lightdm"
        "none"
      ];
      default = "lightdm";
    };

    videoDrivers = mkOption {
      description = ''
        X video drivers. Add "displaylink" for DisplayLink docks; its driver is
        unfree and has to be fetched manually (see the nixpkgs displaylink
        package).
      '';
      type = types.listOf types.str;
      default = [ "modesetting" ];
    };
  };

  config = mkIf config.xserver.enable {
    services.xserver = {
      enable = true;
      videoDrivers = config.xserver.videoDrivers;

      displayManager.lightdm.enable = config.xserver.displayManager == "lightdm";

      displayManager = {
        defaultSession = "nixsession";
        session = [
          {
            name = "nixsession";
            manage = "desktop";
            start = "";
          }
        ];
        # Route DisplayLink outputs through the primary GPU
        sessionCommands = mkIf (elem "displaylink" config.xserver.videoDrivers) ''
          ${lib.getBin pkgs.xorg.xrandr}/bin/xrandr --setprovideroutputsource 2 0
        '';
      };
    };
  };
}
