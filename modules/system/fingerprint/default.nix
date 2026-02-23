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
  };

  config = mkIf config.fingerprint.enable {
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
  };
}
