# Flatpak

Enables Flatpak support by configuring the necessary XDG data directories so that Flatpak-installed applications are visible to the desktop environment.

## Usage

```nix
flatpak.enable = true;
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Enable Flatpak |

## Notes

- This module only sets up the user-side environment variables (`XDG_DATA_DIRS`). The system-level Flatpak service must be enabled separately.
