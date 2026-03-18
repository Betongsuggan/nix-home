# Game Streaming

Configures game streaming with Sunshine (server) and Moonlight (client). The server mode sets up Sunshine with Hyprland virtual monitor management, automatic Steam Big Picture launching, and optimized codec settings for low-latency streaming.

## Usage

```nix
# Server (host games to other devices)
game-streaming.server = {
  enable = true;
  display = "SUNSHINE";
  workspace = 10;
  hdr = true;
};

# Client (connect to a Sunshine server)
game-streaming.client.enable = true;
```

## Options

### Server

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| server.enable | bool | false | Enable game streaming server (Sunshine) |
| server.display | string | "DP-1" | Display connector or virtual monitor name to use for streaming |
| server.workspace | int | 10 | Workspace number dedicated for streaming |
| server.hdr | bool | true | Enable HDR streaming support (requires HEVC Main10 or AV1 10-bit) |

### Client

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| client.enable | bool | false | Enable game streaming client (Moonlight) |

## Notes

- The server creates helper scripts (`prepare-streaming-session` and `restore-monitors`) that manage a Hyprland virtual monitor lifecycle: creating it when a stream starts and restoring physical monitors when it ends.
- Sunshine is configured with AV1 and HEVC auto-negotiation, optimized for AMD VCN5 encoding.
- LAN encryption is disabled for lower latency; WAN encryption remains on.
- The `uinput` kernel module is loaded automatically for virtual input device support.
- After enabling the server, pair clients by visiting the Sunshine web UI at `https://localhost:47990`.
