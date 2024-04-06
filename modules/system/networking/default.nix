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
      networking = {
        inherit (config.networkmanager) hostName;
        
        wireless.enable = false;
        networkmanager = {
          enable = true;
          dispatcherScripts = [
            {
              type = "up";
              source = "${notifier}/bin/network-notifier.sh";
            }
          ];
        };
        useDHCP = false;
      };
  };
}

