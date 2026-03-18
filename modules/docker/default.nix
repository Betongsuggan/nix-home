{ config, lib, pkgs, ... }:
with lib;

{
  options.docker = { enable = mkEnableOption "Enable Docker"; };

  config = mkIf config.docker.enable {

    environment.systemPackages = [ pkgs.docker-compose ];

    # Allow rootless Docker to bind to privileged ports (< 1024)
    boot.kernel.sysctl."net.ipv4.ip_unprivileged_port_start" = 0;

    # Set DOCKER_HOST environment variable for rootless mode
    environment.sessionVariables.DOCKER_HOST = "unix:///run/user/1000/docker.sock";

    virtualisation.docker = {
      enable = true;
      rootless = {
        enable = true;
        setSocketVariable = true;
      };
      daemon.settings = { features = { buildkit = true; }; };
    };
  };
}
