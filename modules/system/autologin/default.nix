{ config, lib, pkgs, ... }:

with lib;

{
  options.autologin = {
    enable = mkEnableOption "Enable autologin functionality";
    
    user = mkOption {
      type = types.str;
      description = "Username to automatically login";
    };
    
    session = mkOption {
      type = types.str;
      default = "hyprland";
      description = "Desktop session to start automatically";
    };
  };

  config = mkIf config.autologin.enable {
    # Configure autologin based on display manager
    services.xserver.displayManager = mkIf config.wayland.enable {
      gdm = {
        autoSuspend = false;
        settings = {
          daemon = {
            AutomaticLoginEnable = true;
            AutomaticLogin = config.autologin.user;
          };
        };
      };
    };

    # Ensure the user has no password requirement
    users.users.${config.autologin.user} = {
      hashedPassword = "";
      initialHashedPassword = "";
    };

    # Allow passwordless sudo for the autologin user (gaming convenience)
    security.sudo.extraRules = [{
      users = [ config.autologin.user ];
      commands = [{
        command = "ALL";
        options = [ "NOPASSWD" ];
      }];
    }];
  };
}