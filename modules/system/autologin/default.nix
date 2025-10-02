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

    method = mkOption {
      type = types.enum [ "gdm" "getty" ];
      default = "gdm";
      description = "Autologin method to use (gdm for display manager, getty for console)";
    };

    tty = mkOption {
      type = types.str;
      default = "tty1";
      description = "TTY to use for getty autologin";
    };
  };

  config = mkIf config.autologin.enable {
    # Configure autologin based on method
    services.xserver.displayManager = mkIf (config.autologin.method == "gdm" && config.wayland.enable) {
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

    # Getty-based autologin for console/minimal setups
    systemd.services."getty@${config.autologin.tty}" = mkIf (config.autologin.method == "getty") {
      overrideStrategy = "asDropin";
      serviceConfig = {
        ExecStart = [
          ""
          "${pkgs.util-linux}/sbin/agetty --autologin ${config.autologin.user} --noclear --keep-baud ${config.autologin.tty} 115200,38400,9600 $TERM"
        ];
      };
    };

    # Ensure the autologin user has empty password for autologin to work
    users.users.${config.autologin.user} = {
      hashedPassword = mkDefault "";
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