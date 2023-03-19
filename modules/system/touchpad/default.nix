{ config, lib, pkgs, ... }:
with lib;

let
  cfg = config.br.touchpad;
in {
  options.br.touchpad = {
    enable = mkEnableOption "Enable touchpad support";
  };

  config = mkIf cfg.enable {
    services.xserver.libinput.enable = true;
    services.xserver.libinput.touchpad.tapping = true;
  };
}
