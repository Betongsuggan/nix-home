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
      wireless.enable = false;
      extraHosts = ''
        127.0.0.1 bits.execute-api.localhost.localstack.cloud
      '';
      networkmanager = {
        enable = true;
        dispatcherScripts = [
          {
            type = "pre-up";
            source = "${notifier}/bin/network-notifier";
          }
        ];
        wifi.scanRandMacAddress = false;
      };
      useDHCP = false;
    };
  };
}
