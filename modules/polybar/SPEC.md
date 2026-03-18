# Polybar

Configures a Polybar status bar for i3 with modules for workspaces, date/time, PulseAudio volume, battery, backlight, CPU, and memory usage. Positioned at the bottom of the screen with a system tray.

## Usage

```nix
polybar = {
  enable = true;
  monitor = "eDP-1";
  battery.device = "BAT0";
  battery.adapter = "ADP1";
  backlight.card = "intel_backlight";
};
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Enable Polybar |
| monitor | str | "eDP-1" | Monitor output name for the polybar |
| audioSink | str or null | null | PulseAudio sink name. null uses the default sink |
| battery.device | str | "BAT0" | Battery device name (from /sys/class/power_supply/) |
| battery.adapter | str | "ADP1" | AC adapter device name (from /sys/class/power_supply/) |
| backlight.card | str | "intel_backlight" | Backlight card name (from /sys/class/backlight/). Common values: intel_backlight, amdgpu_bl0, amdgpu_bl1, acpi_video0 |

## Notes

- Designed for use with i3 (uses `wm-restack = "i3"` and an i3 workspace module).
- Built with PulseAudio support enabled.
- Uses the theme module's font and color settings (`config.theme`).
- Includes a launch script that kills existing Polybar instances before starting.
