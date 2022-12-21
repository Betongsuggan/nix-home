{ config, lib, pkgs, ... }:
with lib;

let
  cfg = config.br.xserver;
in {
  options.br.xserver = {
    enable = mkEnableOption "Enable X server";

    displayManager = mkOption {
      description = "Display manager to use";
      type = types.str;
      default = "lightdm";
    };
    videoDrivers = [ "displaylink" "modesetting" ];
  };

  config = mkIf cfg.enable {
    services.gvfs.enable = true;
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
