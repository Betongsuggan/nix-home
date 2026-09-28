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
  };

  config = mkIf config.my.fingerprint.enable {
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
      genAttrs [ "login" "sudo" "su" "polkit-1" ] (_: {
        fprintAuth = true;
        rules.auth.fprintd.modulePath = mkForce "${pkgs.pam-fprint-grosshack}/lib/security/pam_fprintd_grosshack.so";
      })
      // {
        # hyprlock reads the finger itself over D-Bus while taking the
        # password through PAM; a PAM fingerprint step would ask twice
        hyprlock.fprintAuth = false;
      };
  };
}
