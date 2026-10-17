# Hue Sync

Makes Philips Hue lights follow the screen: [HyperHDR](https://github.com/awawa-dev/HyperHDR) captures the output through the PipeWire screencast portal, averages the configured screen regions and streams the colours to the Hue bridge over the Entertainment API (CLIP v2, DTLS, up to ~25 updates/s). Philips' own Hue Sync app is Windows/macOS only; this is the Linux equivalent, declared in Nix.

Home Manager only (`my.hue-sync`). The NixOS side it needs, the screencast portal, already comes from `my.window-manager`. Nothing listens for inbound traffic: the bridge is reached outbound on the LAN.

How it is declarative: HyperHDR keeps its settings in a SQLite database (`<dataDir>/db/hyperhdr.db`), not a config file. `hue-sync-apply-config` runs as `ExecStartPre` of the `hue-sync` user service and replaces the managed settings rows (`general`, `device`, `leds`, `systemControl`, `videoControl`, `systemGrabber`, `color`, `foregroundEffect`, `webConfig`, plus whatever `extraSettings` names) with the values rendered from the options. The two bridge keys are read from files at that moment, so they never enter the Nix store. Rows the module does not manage (the portal restore token, HyperHDR's web-UI password, undeclared settings types) are left alone. Changing a managed setting in the web UI lasts until the next service start.

## Usage

```nix
my.hue-sync = {
  enable = true;
  bridge = {
    address = "192.168.50.20";                   # hue-sync-setup discover
    appKeyFile = "/run/secrets/hue-app-key";     # sops, owner = this user
    clientKeyFile = "/run/secrets/hue-client-key";
  };
  entertainmentArea = "7b4e6d0a-...";            # hue-sync-setup areas
  channels = [ "left" "right" ];                 # one region per channel, in channel order
  # capture = { fps = 25; width = 512; hdrToneMapping = false; };
  # brightness = 1.0;
  # extraSettings.smoothing.time_ms = 150;
};
```

The host declares the keys (per-host vault file, owner = the syncing user):

```nix
sops.secrets = {
  "hue-app-key" =    { key = "services/hue/app-key";    owner = "gamer"; mode = "0400"; };
  "hue-client-key" = { key = "services/hue/client-key"; owner = "gamer"; mode = "0400"; };
};
```

## Setup

1. **Entertainment area in the Hue app**: Settings → Entertainment areas → create one with the lights around the monitor and place them on the map (left/right of the screen). Note the number of lights: each becomes a channel.
2. **Pair with the bridge** (once; any user on the host):
   ```
   hue-sync-setup discover          # bridge IP, or read it from the Hue app
   hue-sync-setup pair <bridge-ip>  # press the bridge's link button when asked
   ```
   It prints a `hue:` block with `app-key` and `client-key`. Put it in the vault under the host's `services:` group (the `key` paths above):
   ```
   sops nix-vault/secrets/<host>.yaml
   ```
   then bump the `nix-vault` input (`nix flake update nix-vault`). These are machine secrets: vault, never Vaultwarden.
3. **Declare it**: `bridge.address`, the two `*File` paths, and the `sops.secrets` entries on the host. Rebuild. The secrets must exist in the vault before this rebuild, or sops activation fails.
4. **Pick the area and lay out the channels**:
   ```
   hue-sync-setup areas
   ```
   lists each area's `entertainmentArea` id and its channels with positions (x: -1 left … 1 right). Set `entertainmentArea`, and `channels` with one region per channel in that order, e.g. a lamp at x=-1 gets `"left"`. Rebuild.
5. **First start, in the syncing user's session**: the Hyprland share picker appears (floating, centred) when the service starts. Pick the monitor (DP-2), leave "allow restore token" ticked (pre-checked by `my.window-manager.hyprland`), Share. The token is stored in HyperHDR's DB and carries the output name, so later starts and reboots are silent as long as that output exists. If the picker is hidden behind a fullscreen game, press Mod to reach it, or `systemctl --user restart hue-sync` from a terminal.
6. **Check**: `journalctl --user -u hue-sync -f` should show `Entertainment Group ... channels found` and a running PipeWire grabber. The web UI at `http://localhost:8090` has a live LED preview under "LED Visualization".

Stopping the service (`systemctl --user stop hue-sync`) restores the lights to the state they had before the stream (`restoreLightsOnStop`).

## Controls

`hue-sync` talks to the running HyperHDR over its JSON-RPC on localhost (no token needed locally) and reports every action as a notification, so it is made for the launcher: with `launcherEntries` (default on) vicinae lists one "Hue Sync: ..." entry per action.

| Command | Launcher entry | What it does |
|---------|----------------|--------------|
| `hue-sync status` | Hue Sync: Status | HyperHDR's view (stream open, visible source, brightness, saturation) and the bridge's view of the area (active/inactive, owner) |
| `hue-sync on` | Hue Sync: On | Resume: re-enables all components and opens the entertainment stream |
| `hue-sync off` | Hue Sync: Off | Pause: closes the stream and restores the lamps' previous state (`restoreLightsOnStop`), no retries. Use this before using the lamps from the phone |
| `hue-sync toggle` | | `off` while streaming, else `on` |
| `hue-sync reconnect` | Hue Sync: Reconnect | Restarts the screen grabber (new portal session, reuses the saved token) and re-opens the stream. The fix after the Hue app took the lamps over, after a bridge blip, or after the grabber died ("no more input formats") |
| `hue-sync preset <name>` | Hue Sync: Subtle / Normal / Vivid | Applies a look from `presets` (brightness, saturation gain, luminance gain) |
| `hue-sync brightness <0-100\|up\|down>` | Hue Sync: Brighter / Dimmer | Sets or steps (`brightnessStep`) the brightness |

Presets and brightness are live adjustments only: a service start returns to the declared `color` settings. Phone override: a scene set from the Hue app stops the bridge-side stream while HyperHDR may keep streaming into the void, so the lamps stay on the scene and nothing recovers by itself; "Hue Sync: Reconnect" is the way back. Note that `off`/reconnect restore the state the lamps had before the stream started, not the phone's scene. HyperHDR's own retry (`device.maxRetry`, 60 tries 3 s apart) only covers errors it notices, such as a lost DTLS connection.

`my.hue-sync.command` is the `hue-sync` package, for a keybind in `my.window-manager.keybinds` if wanted.

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Enable the `hue-sync` user service (HyperHDR) |
| package | package | `pkgs.hyperhdr` | HyperHDR, built with PipeWire (nixpkgs' is) |
| bridge.address | str | (required) | Bridge IP or hostname, optionally `:port` |
| bridge.appKeyFile | str | (required) | File with the bridge application key (`username` from pairing) |
| bridge.clientKeyFile | str | (required) | File with the Entertainment client key (`clientkey` from pairing) |
| entertainmentArea | str | (required) | Id of the entertainment area (`hue-sync-setup areas`) |
| channels | list of (region name or `{hmin,hmax,vmin,vmax}`) | `[ "left" "right" ]` | Screen region per channel, in channel order. Names: left, right, top, bottom, top-left, top-right, bottom-left, bottom-right, center, full. Fractions: h 0 (left)–1 (right), v 0 (top)–1 (bottom) |
| capture.fps | int 5–120 | 25 | Capture rate; the bridge accepts ~25/s |
| capture.width | int 196–1280 | 512 | Width the frame is scaled to before averaging |
| capture.hdrToneMapping | bool | false | HyperHDR's LUT tone mapping of the captured frame |
| brightness | float 0.5–10 | 1.0 | Brightness factor on the streamed colours |
| restoreLightsOnStop | bool | true | Restore the lights' previous state when the stream stops |
| webUi.port | port | 8090 | HyperHDR web UI on localhost (TLS on `port + 2`) |
| dataDir | str | `~/.local/share/hue-sync` | HyperHDR user data (settings DB, LUT, portal token) |
| presets | attrs of { brightness 0–100, saturationGain 0–10, luminanceGain 0–10 } | subtle (40 %, 0.8), normal, vivid (1.5, 1.2) | Runtime looks for `hue-sync preset` and the launcher |
| brightnessStep | int 1–100 | 10 | Step for `hue-sync brightness up\|down` |
| launcherEntries | bool | true | Install the "Hue Sync: ..." desktop entries |
| command | package (read-only) | the `hue-sync` CLI | For keybinds |
| extraSettings | attrs | `{}` | More HyperHDR settings by type (`smoothing`, `color`, `device`, …), merged over the generated ones |

## Commands

- `hue-sync-setup discover | pair [bridge] | areas [bridge] [app-key-file]`: bridge discovery, pairing, entertainment-area listing. `pair` and `areas` default to the configured bridge and key file.
- `hue-sync status | on | off | toggle | reconnect | preset <name> | brightness <value|up|down>`: runtime control, see Controls.
- `hue-sync-apply-config`: what the service runs before HyperHDR; rerun by hand after editing the DB if needed.

## Notes

- HyperHDR also auto-picks any V4L2 device (a webcam) as a "USB grabber" source, and that source outranks the screen grabber (priority 240 vs 245). The module keeps it out of the instance (`videoControl.videoInstanceEnable = false`); with it in, the lights follow the camera image: a dark room gives dim white lamps.
- HyperHDR only tries the PipeWire/portal grabber for a GUI app, so the service runs it with `--service --pipewire` (forced portal grabber, no systray).
- LED index i is entertainment channel i, in the order the bridge returns them (`channel_id` ascending, which follows the Hue app's layout). A mismatch between `channels` and the area's channel count is not an error: extra channels get nothing, extra regions are ignored.
- HyperHDR's PipeWire grabber only accepts 8-bit formats (BGRx/RGBx/BGRA/RGBA), while Hyprland gives screencopy clients the monitor's current format: a 10-bit output means XBGR2101010, and the stream dies with "no more input formats" as soon as the output is in 10-bit (at start, or at the next HDR/fullscreen transition), after which nothing recovers by itself. On Hyprland the module therefore sets `misc:screencopy_force_8b = true` for the user's session, which makes Hyprland read back 8-bit for every screencopy client there. Sunshine captures through KMS, so HDR streaming is unaffected. The frames are SDR-mapped, which is right for ambient light; `capture.hdrToneMapping` is the knob if a game looks washed out.
- HyperHDR can't load EGL on NixOS ("could not open EGL library"), so it uses shared-memory frames instead of DMA-BUF. Harmless at 25 fps, and DMA-BUF would not fix the format problem above: HyperHDR's DMA formats are 8-bit too.
- Expect ~100 ms of lag between screen and lights. Philips' own app has the same.
- Sunshine and HyperHDR both use screencast portals in the gamer session (`xdg-desktop-portal-wlr` and `-hyprland`); the Hyprland one answers first and handles the restore token. Two capture streams of the same output are fine for the compositor.
