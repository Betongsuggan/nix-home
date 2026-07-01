# Game Streaming

Unified module with independent server and client halves. The server (`system.nix`) configures Sunshine with Hyprland virtual monitor management. The client (`user.nix`) configures Moonlight with declarative settings. Server and client are independent — enable each where needed.

## Usage

```nix
# Server (in system config — host games to other devices)
game-streaming.server = {
  enable = true;
  display = "SUNSHINE";
  workspace = 10;
  hdr = true;
};

# Client (in user config — connect to a Sunshine server)
game-streaming.client.enable = true;
```

## Options (server — system.nix)

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| server.enable | bool | false | Enable game streaming server (Sunshine) |
| server.display | string | "DP-1" | Display connector or virtual monitor name to use for streaming |
| server.workspace | int | 10 | Workspace number dedicated for streaming |
| server.hdr | bool | true | Enable HDR streaming support (requires HEVC Main10 or AV1 10-bit) |

## Options (client — user.nix)

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

- The server creates helper scripts (`prepare-streaming-session` and `restore-monitors`). The headless virtual monitor (`display`) is treated as **persistent for the entire boot**: `hypr-virtual-monitors.service` materializes it once at session start, `prepare-streaming-session` (re)configures its resolution to the connecting client and disables physical monitors, and `restore-monitors` only re-enables the physical monitors — it does **not** tear down the virtual monitor. Removing it between sessions would leave Sunshine with an empty monitor list at its next encoder probe (sunshine has no equivalent of the oneshot to re-create it), causing every encoder to "fail" and `/launch` to return 503.
- A systemd-user oneshot `hypr-virtual-monitors.service` materializes the headless `display` monitor at session start and is ordered before `sunshine.service`. Sunshine `autoStart` is therefore set to `false` on the upstream module and re-wired via a drop-in (`Wants=`/`After=hypr-virtual-monitors.service`, `WantedBy=graphical-session.target`) — this avoids a race where Sunshine would start before the monitor existed and crash-loop with an empty Wayland monitor list.
- Sunshine is configured with AV1 and HEVC auto-negotiation, optimized for AMD VCN5 encoding.
- LAN encryption is disabled for lower latency; WAN encryption remains on. Tailscale's CGNAT range (`100.64.0.0/10`) is classified as WAN by Sunshine — `origin_pin_allowed` and `origin_web_ui_allowed` are set to `wan` so tailnet clients (Moonlight on Android handhelds, etc.) can pair and access the admin UI.
- The `uinput` kernel module is loaded automatically for virtual input device support.
- After enabling the server, pair clients by visiting the Sunshine web UI at `https://localhost:47990` (or `https://<host>.ts.rydback.net:47990` over tailnet).
- The client configuration file is written to `~/.config/Moonlight Game Streaming Project/Moonlight.conf`.
- HDR streaming requires HEVC or AV1 codec support on both host and client.
