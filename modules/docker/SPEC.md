# Docker

Enables Docker in rootless mode with BuildKit and docker-compose. Configures unprivileged port binding so rootless containers can listen on ports below 1024.

## Usage

```nix
my.docker.enable = true;
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Enable Docker |

## Notes

- Runs in rootless mode, **on demand**: `$XDG_RUNTIME_DIR/docker.sock` is a socket-activated user socket, and the first connection starts the rootless daemon (on a private `docker-daemon.sock`) plus a `systemd-socket-proxyd` proxy to it. Nothing Docker runs at login; once started it stays up until logout. `dockerd-rootless` can't take a systemd socket itself, hence the proxy.
- The rootful daemon is configured but **not started at boot** (`enableOnBoot = false`).
  Because `DOCKER_HOST` points every client at the rootless socket, the rootful daemon had
  no clients and was holding open `dockerd` + `containerd` (~180 MB) at zero connections.
  It remains reachable through socket activation on `/var/run/docker.sock` for the rare
  case that something needs it, and the `docker` group is still created.
- Containers with a restart policy are only resurrected by the daemon that owns them, so a
  rootless container set to `--restart=unless-stopped` comes back at login, not at boot.
- `rootless.setSocketVariable` points `DOCKER_HOST` at each user's own rootless socket (`$XDG_RUNTIME_DIR/docker.sock`) in login shells. Sets `net.ipv4.ip_unprivileged_port_start = 0` to allow binding privileged ports.
- BuildKit is enabled by default in the daemon configuration.
- Installs `docker-compose` system-wide.
