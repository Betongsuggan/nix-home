{
  config,
  lib,
  pkgs,
  ...
}:
with lib;

{
  options.my.network-manager = {
    enable = mkEnableOption "Enable network management";

    hostName = mkOption {
      description = "Hostname of the system";
      type = types.str;
      default = "nixos";
    };
  };

  config = mkIf config.my.network-manager.enable {
    environment.systemPackages = [ pkgs.networkmanager ];
    networking = {
      inherit (config.my.network-manager) hostName;

      # iwd with settings to create the interface
      wireless.iwd = {
        enable = true;
        settings = {
          DriverQuirks = {
            DefaultInterface = true; # Creates wlan0 automatically
          };
          Settings = {
            AutoConnect = true;
          };
        };
      };

      # NetworkManager using iwd as wifi backend
      networkmanager = {
        enable = true;
        wifi.backend = "iwd";
      };
    };
  };
}
