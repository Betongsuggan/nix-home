# Kanshi

Enables the Kanshi dynamic display configuration daemon for Wayland, which automatically applies output profiles when monitors are connected or disconnected.

## Usage

```nix
kanshi.enable = true;
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Enable Kanshi |

## Notes

- Ships with two hardcoded output profiles:
  - **work**: DP-3 at 3840x2560 (scale 1.25) + eDP-1 at 1920x1200
  - **home**: DP-2 at 3440x1440@100Hz (scale 1.0) + eDP-1 at 1920x1200
- Only useful on Wayland compositors that support the wlr-output-management protocol (Hyprland, Sway, etc.).
