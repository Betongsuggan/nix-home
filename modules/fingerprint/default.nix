{ config, lib, pkgs, ... }:
with lib;

let
  driverPackages = {
    goodix = pkgs.libfprint-2-tod1-goodix;
    elan = pkgs.libfprint-2-tod1-elan;
    # Generic/built-in drivers don't need a TOD package
    generic = null;
  };
in {
  options.fingerprint = {
    enable = mkEnableOption "Enable fingerprint reader";

    driver = mkOption {
      type = types.enum [ "goodix" "elan" "generic" ];
      default = "goodix";
      description = ''
        Fingerprint reader driver to use.
        - goodix: For Goodix fingerprint readers (common in many laptops)
        - elan: For ELAN fingerprint readers
        - generic: Use built-in libfprint drivers (no TOD driver)
      '';
      example = "elan";
    };

    clamshellAware = mkEnableOption "Stop fprintd when lid is closed so PAM falls back to password auth";

    lidStatePath = mkOption {
      type = types.str;
      default = "/proc/acpi/button/lid/LID0/state";
      description = ''
        Path to the ACPI lid state file. Check /proc/acpi/button/lid/ for the
        correct entry name on your hardware (LID0, LID, etc.).
      '';
      example = "/proc/acpi/button/lid/LID/state";
    };
  };

  config = mkIf config.fingerprint.enable (mkMerge [
    {
      environment.systemPackages = [
        pkgs.fprintd
      ];

      services.fprintd = {
        enable = true;
      } // (if driverPackages.${config.fingerprint.driver} != null then {
        tod = {
          enable = true;
          driver = driverPackages.${config.fingerprint.driver};
        };
      } else {});

      security.pam.services.login.fprintAuth = true;
      security.pam.services.sudo.fprintAuth = true;
      security.pam.services.su.fprintAuth = true;
      security.pam.services.polkit-1.fprintAuth = true;
      # Note: hyprlock uses native D-Bus fprintd integration, not PAM
    }

    (mkIf config.fingerprint.clamshellAware {
      services.acpid = {
        enable = true;
        handlers = {
          lid-close-fingerprint = {
            event = "button/lid.* close";
            action = "${pkgs.systemd}/bin/systemctl stop fprintd.service";
          };
          lid-open-fingerprint = {
            event = "button/lid.* open";
            action = "${pkgs.systemd}/bin/systemctl start fprintd.service";
          };
        };
      };

      systemd.services.fprintd-lid-check = {
        description = "Stop fprintd if laptop lid is closed at boot";
        wantedBy = [ "multi-user.target" ];
        after = [ "fprintd.service" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = pkgs.writeShellScript "fprintd-lid-check" ''
            if [ -f "${config.fingerprint.lidStatePath}" ] && \
               grep -q "closed" "${config.fingerprint.lidStatePath}"; then
              systemctl stop fprintd.service || true
            fi
          '';
        };
      };
    })
  ]);
}
