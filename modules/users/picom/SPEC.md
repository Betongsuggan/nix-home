# Picom

Enables the Picom compositor for X11 with GLX backend, fade animations, and VSync.

## Usage

```nix
picom.enable = true;
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Enable Picom service |

## Notes

- Uses GLX backend with VSync enabled.
- Fade transitions are enabled with steps of 0.1 (in) and 0.12 (out).
- Only relevant for X11 window managers (e.g., i3). Wayland compositors handle compositing natively.
