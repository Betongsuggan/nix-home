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
  };

  config = mkIf config.my.network-manager.enable {
    users.users = genAttrs config.my.common.admins (_: {
      extraGroups = [ "networkmanager" ];
    });

    environment.systemPackages = [ pkgs.networkmanager ];
    networking = {
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
