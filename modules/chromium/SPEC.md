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
- Pre-installed extensions: uBlock Origin, Bitwarden, Vimium.
- Wayland support via `--ozone-platform-hint=auto` and `UseOzonePlatform` feature flag.
- Hardware acceleration enabled with `--enable-gpu-rasterization` and `--enable-zero-copy`.
- MediaRouter (Google Cast) disabled for privacy.
- Extensions are managed via Chrome Web Store IDs through the home-manager chromium module.
