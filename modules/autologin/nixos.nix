{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

{
  options.my.autologin = {
    enable = mkEnableOption "Enable autologin functionality";

    user = mkOption {
      type = types.str;
      description = "Username to automatically login";
    };

    session = mkOption {
      type = types.str;
      default = "hyprland";
      description = "Desktop session to start automatically (gdm method only)";
    };

    method = mkOption {
      type = types.enum [
        "gdm"
        "getty"
      ];
      default = "gdm";
      description = "Autologin method to use (gdm for display manager, getty for console)";
    };

    tty = mkOption {
      type = types.str;
      default = "tty1";
      description = "TTY to use for getty autologin";
    };
  };

  config = mkIf config.my.autologin.enable {
    # GDM autologin straight into the configured Wayland session
    services.displayManager = mkIf (config.my.autologin.method == "gdm") {
      gdm = {
        enable = true;
        autoSuspend = false;
      };
      autoLogin = {
        enable = true;
        user = config.my.autologin.user;
      };
      defaultSession = config.my.autologin.session;
    };

    # Getty-based autologin for console/minimal setups
    systemd.services."getty@${config.my.autologin.tty}" = mkIf (config.my.autologin.method == "getty") {
      overrideStrategy = "asDropin";
      serviceConfig = {
        ExecStart = [
          ""
          "${pkgs.util-linux}/sbin/agetty --autologin ${config.my.autologin.user} --noclear --keep-baud ${config.my.autologin.tty} 115200,38400,9600 $TERM"
        ];
        # Don't restart so quickly if the session exits
        RestartSec = "5";
      };
    };

    # Empty password so the unprivileged autologin user can unlock its own
    # session; it is deliberately granted no sudo rights
    users.users.${config.my.autologin.user} = {
      hashedPassword = mkDefault "";
    };
  };
}
