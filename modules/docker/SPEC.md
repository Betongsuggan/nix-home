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
- Sets `DOCKER_HOST` session variable and `net.ipv4.ip_unprivileged_port_start = 0` to allow binding privileged ports.
- BuildKit is enabled by default in the daemon configuration.
- Installs `docker-compose` system-wide.
