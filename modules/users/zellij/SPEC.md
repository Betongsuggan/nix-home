# Zellij

Enables the Zellij terminal multiplexer with a simplified UI, custom default layout, and a Gruvbox color theme derived from the theming module.

## Usage

```nix
zellij.enable = true;
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Enable Zellij |

## Notes

- Requires the `theme` module to be enabled, as the Gruvbox theme colors reference `config.theme.colors`.
- Uses a custom default layout from `layouts/default.kdl`.
- Configured with `simplified_ui = true`, `pane_frames = false`, and rounded corners.
