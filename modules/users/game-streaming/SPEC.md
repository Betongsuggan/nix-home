# Game Streaming

Configures the Moonlight game streaming client with declarative settings for resolution, codec, HDR, and other streaming parameters. Generates the Moonlight Qt configuration file automatically.

## Usage

```nix
game-streaming.client = {
  enable = true;
  resolution = { width = 2560; height = 1440; };
  fps = 120;
  bitrate = 100000;
  codec = "hevc";
  hdr = true;
};
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| client.enable | bool | false | Enable Moonlight game streaming client |
| client.resolution.width | int | 1920 | Stream resolution width |
| client.resolution.height | int | 1080 | Stream resolution height |
| client.fps | int | 120 | Target frame rate for streaming |
| client.bitrate | int | 100000 | Bitrate in Kbps (100000 = 100 Mbps, good for LAN gaming) |
| client.codec | enum | "auto" | Video codec: "auto", "h264", "hevc", "av1" |
| client.vsync | bool | false | Enable V-Sync (adds latency, disable for gaming) |
| client.hdr | bool | true | Enable HDR streaming when available |
| client.decoder | enum | "auto" | Video decoder: "auto", "hardware", "software" |
| client.framePacing | bool | true | Enable frame pacing for smoother playback |
| client.autoBitrate | bool | false | Auto-adjust bitrate based on network (disable for consistent LAN quality) |
| client.showPerfOverlay | bool | false | Show performance overlay by default |

## Notes

- Requires a Sunshine or GeForce Experience host to stream from.
- The configuration file is written to `~/.config/Moonlight Game Streaming Project/Moonlight.conf`.
- HDR streaming requires HEVC or AV1 codec support on both host and client.
