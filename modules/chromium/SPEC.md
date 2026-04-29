# Chromium (Ungoogled)

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
- Wayland support via `--ozone-platform-hint=auto` and `UseOzonePlatform` feature flag.
- Hardware acceleration: VA-API video decode/encode, GPU rasterization, zero-copy, EGL backend, out-of-process canvas rasterization, GPU blocklist bypassed. Uses native OpenGL path (not Vulkan ANGLE) for optimal compositing performance.
- PipeWire screen capture support via `WebRTCPipeWireCapturer` for Wayland screen sharing.
- Privacy: MediaRouter (Google Cast), Breakpad crash reporting, domain reliability monitoring, and client-side phishing detection all disabled.
- Extensions are managed via Chrome Web Store IDs through the home-manager chromium module.
