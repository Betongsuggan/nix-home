{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.my.sops;
in
{
  options.my.sops = {
    enable = mkEnableOption "tools for editing the nix-vault repository";
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
