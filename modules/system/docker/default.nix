{ config, lib, pkgs, ... }:
with lib;

{
  options.docker = { enable = mkEnableOption "Enable Docker"; };

  config = mkIf config.docker.enable {

    environment.systemPackages = [ pkgs.docker-compose ];

    virtualisation.docker = {
      enable = true;
      rootless = {
        enable = false;
        setSocketVariable = true;
      };
      daemon.settings = { features = { buildkit = true; }; };
    };
  };
}
