# Zellij

Enables the Zellij terminal multiplexer with a simplified UI, custom default layout, and a Gruvbox color theme derived from the theming module.

## Usage

```nix
my.zellij.enable = true;
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Enable Zellij |

## Notes

- Colors come from the theme via `stylix.targets.zellij`.
- Uses a custom default layout from `layouts/default.kdl`.
- Configured with `simplified_ui = true`, `pane_frames = false`, and rounded corners.
