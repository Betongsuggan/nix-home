{ config, lib, pkgs, ... }:
with lib;

{
  options.xserver = {
    enable = mkEnableOption "Enable X server";

    displayManager = mkOption {
      description = "Display manager to use";
      type = types.str;
      default = "lightdm";
    };
    videoDrivers = [ "displaylink" "modesetting" ];
  };

  config = mkIf config.xserver.enable {
    services.xserver = {
      enable = true;

      displayManager = {
        defaultSession = "nixsession";
        session = [
          {
            name = "nixsession";
            manage = "desktop";
            start = "";
          }
        ];
        sessionCommands = ''
          ${lib.getBin pkgs.xorg.xrandr}/bin/xrandr --setprovideroutputsource 2 0
        '';
      };
    };
  };
}
