{ config, lib, pkgs, ... }:
with lib;

{
  options.qutebrowser = {
    enable = mkEnableOption "Enable qutebrowser";
  };

  config = mkIf config.qutebrowser.enable {
    home-manager.users.${config.user}.programs = {
      qutebrowser = {
        enable = true;
      };
    };
  };
}
