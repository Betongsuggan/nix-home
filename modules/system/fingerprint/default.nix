{ config, lib, pkgs, ... }:
with lib;

{
  options.fingerprint = {
    enable = mkEnableOption "Enable fingerprint reader";
  };

  config = mkIf config.fingerprint.enable {
    environment.systemPackages = [
      pkgs.fprintd
    ];

    services.fprintd = {
      enable = true;
      tod = {
        enable = true;
        driver = pkgs.libfprint-2-tod1-goodix;
      };
    };

    security.pam.services.login.fprintAuth = true;
    security.pam.services.swaylock-fancy.fprintAuth = true;
  };
}
