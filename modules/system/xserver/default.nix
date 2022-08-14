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
  };

  config = mkIf (cfg.enable) {
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
      };
    };
  };
}
