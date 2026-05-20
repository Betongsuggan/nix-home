{ config, lib, ... }:

with lib;

let cfg = config.openssh;
in {
  options.openssh = {
    enable = mkEnableOption "OpenSSH server (sshd)";

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = "Open port 22 in the firewall.";
    };

    permitRootLogin = mkOption {
      type = types.enum [
        "yes"
        "without-password"
        "prohibit-password"
        "forced-commands-only"
        "no"
      ];
      default = "no";
      description = "Value of sshd's `PermitRootLogin` option.";
    };

    passwordAuthentication = mkOption {
      type = types.bool;
      default = false;
      description = "Allow password-based logins. Off by default; only key-based auth is permitted.";
    };
  };

  config = mkIf cfg.enable {
    services.openssh = {
      enable = true;
      openFirewall = cfg.openFirewall;
      settings = {
        PasswordAuthentication = cfg.passwordAuthentication;
        PermitRootLogin = cfg.permitRootLogin;
      };
    };
  };
}
