{ config, lib, pkgs, ... }:
with lib;

let notifier = import ./networkNotifier.nix { inherit pkgs; };
in {
  options.networkmanager = {
    enable = mkEnableOption "Enable network management";

    hostName = mkOption {
      description = "Hostname of the system";
      type = types.str;
      default = "nixos";
    };
  };

  config = mkIf config.networkmanager.enable {
    environment.systemPackages = [ notifier pkgs.networkmanager ];
    networking = {
      inherit (config.networkmanager) hostName;

      # iwd with settings to create the interface
      wireless.iwd = {
        enable = true;
        settings = {
          DriverQuirks = {
            DefaultInterface = true; # Creates wlan0 automatically
          };
          Settings = { AutoConnect = true; };
        };
      };

      # NetworkManager using iwd as wifi backend
      networkmanager = {
        enable = true;
        wifi.backend = "iwd";
      };

      extraHosts = ''
        127.0.0.1 bits.execute-api.localhost.localstack.cloud
      '';
    };
  };
}
