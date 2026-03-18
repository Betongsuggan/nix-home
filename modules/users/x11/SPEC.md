# X11

Enables X11 session support with Gruvbox Dark xresources color configuration and Xft antialiasing.

## Usage

```nix
x11.enable = true;
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Enable X11 |

## Notes

- Enables `xsession` via home-manager.
- Applies a full Gruvbox Dark color scheme to xresources (256-color palette).
- Enables Xft font antialiasing.
