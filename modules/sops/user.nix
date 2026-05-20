{ config, lib, pkgs, ... }:

with lib;

let cfg = config.sops-edit;
in {
  options.sops-edit = {
    enable = mkEnableOption "tools for editing the nix-secrets repository";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      sops
      age
      age-plugin-yubikey
    ];

    home.sessionVariables = {
      SOPS_AGE_KEY_FILE = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
    };
  };
}
