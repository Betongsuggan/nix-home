{ config, lib, pkgs, ... }:
with lib;

{
  options.communication = {
    enable = mkEnableOption "Enable communication tooling";
  };

  config = mkIf (config.communication.enable) {
    home-manager.users.${config.user}.home.packages = with pkgs; [
      slack
      slack-term
    ];

    unfreePackages = [ "slack" ];
  };
}

