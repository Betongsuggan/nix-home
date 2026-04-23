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
- Automatically selects the correct VA-API driver (`radeonsi` for AMD, `iHD`/`i965` for Intel) based on `osConfig.graphics`.
- Pre-installed extensions: uBlock Origin, Bitwarden, Vimium.
- Wayland support via `--ozone-platform-hint=auto` and `UseOzonePlatform` feature flag.
- Hardware acceleration: VA-API video decode/encode, GPU rasterization, zero-copy, Vulkan rendering, EGL backend, GPU blocklist bypassed.
- Privacy: MediaRouter (Google Cast), Breakpad crash reporting, domain reliability monitoring, and client-side phishing detection all disabled.
- Extensions are managed via Chrome Web Store IDs through the home-manager chromium module.
