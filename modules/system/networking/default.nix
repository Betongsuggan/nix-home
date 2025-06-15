{ config, lib, pkgs, ... }:
with lib;

let
  notifier = import ./networkNotifier.nix { inherit pkgs; };
in
{
  options.networkmanager = {
    enable = mkEnableOption "Enable power management";

    hostName = mkOption {
      description = "Hostname of the system";
      type = types.str;
      default = "nixos";
    };
  };

  config = mkIf config.networkmanager.enable {
    environment.systemPackages = [ notifier ];
    networking = {
      inherit (config.networkmanager) hostName;
      wireless = {
        iwd.enable = true;
      };
      useDHCP = true;
      extraHosts = ''
        127.0.0.1 bits.execute-api.localhost.localstack.cloud
      '';
    };
  };
}
