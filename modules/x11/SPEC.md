# X11

Enables X11 session support with Gruvbox Dark xresources color configuration and Xft antialiasing.

## Usage

```nix
my.x11.enable = true;
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Enable X11 |

## Notes

- Enables `xsession` via home-manager.
- Terminal colors in Xresources come from the theme via `stylix.targets.xresources`.
- Enables Xft font antialiasing.
