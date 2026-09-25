{
  config,
  lib,
  pkgs,
  ...
}:
with lib;

let
  # Same daemon.json the upstream rootless unit would pass
  rootlessSettings =
    (pkgs.formats.json { }).generate "daemon.json"
      config.virtualisation.docker.rootless.daemon.settings;
in
{
  options.my.docker = {
    enable = mkEnableOption "Enable Docker";
  };

  config = mkIf config.my.docker.enable {
    users.users = genAttrs config.my.common.admins (_: {
      extraGroups = [ "docker" ];
    });

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

    # Rootless Docker on demand: the user socket at $XDG_RUNTIME_DIR/docker.sock
    # (where DOCKER_HOST points) is socket-activated, and the first connection
    # starts the rootless daemon on a private socket plus a proxy to it.
    # dockerd-rootless can't take a systemd socket itself (rootlesskit).
    systemd.user.services.docker = {
      wantedBy = mkForce [ ];
      serviceConfig.ExecStart = mkForce "${config.virtualisation.docker.rootless.package}/bin/dockerd-rootless --config-file=${rootlessSettings} --host=unix://%t/docker-daemon.sock";
    };
    systemd.user.sockets.docker-proxy = {
      wantedBy = [ "sockets.target" ];
      socketConfig.ListenStream = "%t/docker.sock";
    };
    systemd.user.services.docker-proxy = {
      description = "Proxy to the on-demand rootless Docker daemon";
      requires = [ "docker.service" ];
      after = [ "docker.service" ];
      serviceConfig.ExecStart = "${pkgs.systemd}/lib/systemd/systemd-socket-proxyd %t/docker-daemon.sock";
    };
  };
}
