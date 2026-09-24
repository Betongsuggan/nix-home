# Docker

Enables Docker in rootless mode with BuildKit and docker-compose. Configures unprivileged port binding so rootless containers can listen on ports below 1024.

## Usage

```nix
docker.enable = true;
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Enable Docker |

## Notes

- Runs in rootless mode with the socket at `/run/user/1000/docker.sock`.
- The rootful daemon is configured but **not started at boot** (`enableOnBoot = false`).
  Because `DOCKER_HOST` points every client at the rootless socket, the rootful daemon had
  no clients and was holding open `dockerd` + `containerd` (~180 MB) at zero connections.
  It remains reachable through socket activation on `/var/run/docker.sock` for the rare
  case that something needs it, and the `docker` group is still created.
- Containers with a restart policy are only resurrected by the daemon that owns them, so a
  rootless container set to `--restart=unless-stopped` comes back at login, not at boot.
- Sets `DOCKER_HOST` session variable and `net.ipv4.ip_unprivileged_port_start = 0` to allow binding privileged ports.
- BuildKit is enabled by default in the daemon configuration.
- Installs `docker-compose` system-wide.
