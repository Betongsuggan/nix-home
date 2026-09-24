{
  config,
  lib,
  pkgs,
  ...
}:
with lib;

{
  options.my.docker = {
    enable = mkEnableOption "Enable Docker";
  };

  config = mkIf config.my.docker.enable {

    environment.systemPackages = [ pkgs.docker-compose ];

    # Allow rootless Docker to bind to privileged ports (< 1024)
    boot.kernel.sysctl."net.ipv4.ip_unprivileged_port_start" = 0;

    virtualisation.docker = {
      enable = true;
      package = pkgs.docker_29;

      # Everything here talks to the rootless socket (rootless.setSocketVariable
      # points DOCKER_HOST at $XDG_RUNTIME_DIR/docker.sock per user), so the
      # rootful daemon has no clients -- it was starting at boot and sitting at
      # zero connections, holding open dockerd + containerd for nothing. Keep it
      # configured (the `docker` group and the socket unit come with it) but let
      # socket activation bring it up on the rare occasion something wants it.
      enableOnBoot = false;

      rootless = {
        enable = true;
        setSocketVariable = true;
        package = pkgs.docker_29;
      };
      daemon.settings = {
        features = {
          buildkit = true;
        };
      };
    };
  };
}
