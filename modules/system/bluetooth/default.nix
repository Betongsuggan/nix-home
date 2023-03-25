{ config, lib, pkgs, ... }:
with lib;

let
  cfg = config.br.bluetooth;
in
{
  options.br.bluetooth = {
    enable = mkEnableOption "Enable Bluetooth";
  };

  config = mkIf cfg.enable {
    services.blueman.enable = true;
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
  };
}
