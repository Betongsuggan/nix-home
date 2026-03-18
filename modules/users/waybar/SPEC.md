# Waybar

Configures Waybar, a status bar for Wayland compositors. Includes built-in modules for clock, CPU, GPU, memory, audio, battery, network, media player control (via playerctl), and workspace navigation. Styled using values from the theming module.

## Usage

```nix
waybar.enable = true;
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Enable Waybar |

## Notes

- Requires the `theme` module to be enabled, as the bar styling references `config.theme.colors` and `config.theme.font`.
- The bar is positioned at the bottom of the screen in dock mode.
- Left modules: app menu (wofi launcher), clock, CPU, GPU, memory, audio volume, and media player info.
- Right modules: Sway workspaces, network status, battery, system tray, and hostname.
- GPU usage is read from `/sys/class/drm/card0/device/gpu_busy_percent`.
- Clicking the network widget opens `nmtui-connect` in Alacritty.
- Media player controls use `playerctl`/`playerctld`.
