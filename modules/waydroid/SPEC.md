# Waydroid

Enables Waydroid, an Android container that runs on Wayland compositors. Sets up LXC virtualization and installs the Waydroid CLI tool.

## Usage

```nix
waydroid.enable = true;
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Enable Waydroid Android container |

## Notes

- Requires a Wayland compositor (e.g., Hyprland, Sway).
- After enabling, initialize with `sudo waydroid init` on first use.
