# Chromium (Ungoogled)

Unified module with a user half (`user.nix`) that configures the browser and a system half (`system.nix`) that auto-enables a portal workaround when any user has chromium enabled.

Configures Ungoogled Chromium, a privacy-focused Chromium fork with all Google telemetry and service dependencies removed. Includes Wayland support, hardware acceleration flags, and pre-installed extensions via the home-manager `programs.chromium` module.

## Usage

```nix
chromium.enable = true;
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Enable Ungoogled Chromium browser |

## Notes

- Uses `ungoogled-chromium` package which removes Google telemetry, service integrations, and tracking.
- VA-API driver selection (`LIBVA_DRIVER_NAME`) is handled by the system-level `graphics` module, not this module.
- Pre-installed extensions: uBlock Origin, Bitwarden, Vimium.
- Wayland support via `--ozone-platform-hint=auto` (Ozone is default in modern Chromium, no extra feature flag needed).
- Hardware acceleration: VA-API video decode/encode (including AV1 on VCN 3.0+), GPU rasterization, zero-copy, GL-path accelerated video decode, out-of-process canvas rasterization, GPU blocklist bypassed. Lets Chromium auto-select the GL backend — explicit `--use-gl=egl` was removed because on recent Chromium versions it caused GL/GPU acceleration to fail to initialize on Wayland (resulting in software rendering and software AV1 decode).
- PipeWire screen capture support via `WebRTCPipeWireCapturer` for Wayland screen sharing.
- Privacy: MediaRouter (Google Cast), Breakpad crash reporting, domain reliability monitoring, and client-side phishing detection all disabled.
- Extensions are managed via Chrome Web Store IDs through the home-manager chromium module.
- System half installs `xdg-desktop-portal-gtk` and pins the `FileChooser` portal interface to the gtk backend. Without this, when `XDG_CURRENT_DESKTOP=gnome` (set by niri for screen sharing), the gnome portal delegates FileChooser to Nautilus and silently fails every download because Nautilus is not installed.
