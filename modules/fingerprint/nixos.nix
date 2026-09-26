{
  config,
  lib,
  pkgs,
  ...
}:
with lib;

let
  driverPackages = {
    goodix = pkgs.libfprint-2-tod1-goodix;
    elan = pkgs.libfprint-2-tod1-elan;
    # Generic/built-in drivers don't need a TOD package
    generic = null;
  };
in
{
  options.my.fingerprint = {
    enable = mkEnableOption "Enable fingerprint reader";

    driver = mkOption {
      type = types.enum [
        "goodix"
        "elan"
        "generic"
      ];
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

  config = mkIf config.my.fingerprint.enable (mkMerge [
    {
      environment.systemPackages = [
        pkgs.fprintd
      ];

      services.fprintd = {
        enable = true;
      }
      // (
        if driverPackages.${config.my.fingerprint.driver} != null then
          {
            tod = {
              enable = true;
              driver = driverPackages.${config.my.fingerprint.driver};
            };
          }
        else
          { }
      );

      # Fingerprint or password at the same prompt, whichever comes first:
      # the stock pam_fprintd asks for the finger and only falls back to the
      # password after a timeout. The grosshack module takes NixOS's fprintd
      # rule slot (sufficient, before pam_unix with try_first_pass); a typed
      # password is handed on to pam_unix
      security.pam.services =
        genAttrs [ "login" "greetd" "sudo" "su" "polkit-1" ] (_: {
          fprintAuth = true;
          rules.auth.fprintd.modulePath = mkForce "${pkgs.pam-fprint-grosshack}/lib/security/pam_fprintd_grosshack.so";
        })
        // {
          # hyprlock reads the finger itself over D-Bus while taking the
          # password through PAM; a PAM fingerprint step would ask twice
          hyprlock.fprintAuth = false;
        };
    }

    (mkIf config.my.fingerprint.clamshellAware {
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
            if [ -f "${config.my.fingerprint.lidStatePath}" ] && \
               grep -q "closed" "${config.my.fingerprint.lidStatePath}"; then
              systemctl stop fprintd.service || true
            fi
          '';
        };
      };
    })
  ]);
}
