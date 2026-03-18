{ config, lib, pkgs, ... }:
with lib;

{
  options.qutebrowser = { enable = mkEnableOption "Enable qutebrowser"; };

  config = mkIf config.qutebrowser.enable {
    programs = {
      qutebrowser = { enable = true; };
    };
  };
}
