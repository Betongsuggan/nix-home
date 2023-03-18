{ config, lib, pkgs, ... }:
with lib;

let
  cfg = config.br.fingerprint;
in {
  options.br.fingerprint = {
    enable = mkEnableOption "Enable fingerprint reader";
  };

  config = mkIf cfg.enable {
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
