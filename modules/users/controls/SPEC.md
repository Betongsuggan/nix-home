# Controls

Unified system controls module providing brightness, volume, media player, power management, and utility scripts with desktop notification integration. Each sub-control can be independently enabled and is window-manager-aware.

## Usage

```nix
controls = {
  enable = true;
  windowManager = "hyprland";

  brightness = {
    enable = true;
    backend = "brightnessctl";
    notifications = true;
  };

  volume = {
    enable = true;
    backend = "pamixer";
    notifications = true;
  };

  mediaPlayer = {
    enable = true;
    notifications = true;
  };

  power = {
    enable = true;
    confirmActions = true;
    notifications = true;
  };

  utils = {
    enable = true;
    time = true;
    battery = true;
    system = true;
    workspaces = true;
    autoScreenRotation = false;
  };
};
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Enable system controls |
| windowManager | enum: "hyprland", "i3", "niri", "sway", "generic" | "generic" | Window manager type for controls integration |
| brightness.enable | bool | true | Enable brightness controls |
| brightness.backend | enum: "light", "brightnessctl" | "light" | Brightness control backend |
| brightness.notifications | bool | true | Enable brightness change notifications |
| volume.enable | bool | true | Enable volume controls |
| volume.backend | enum: "pamixer", "pactl" | "pamixer" | Volume control backend |
| volume.notifications | bool | true | Enable volume change notifications |
| mediaPlayer.enable | bool | true | Enable media player controls |
| mediaPlayer.notifications | bool | true | Enable media player notifications |
| power.enable | bool | true | Enable power management controls |
| power.confirmActions | bool | true | Require confirmation for destructive power actions |
| power.notifications | bool | true | Enable power action notifications |
| utils.enable | bool | true | Enable utility notifications |
| utils.time | bool | true | Enable time notifications |
| utils.battery | bool | true | Enable battery notifications |
| utils.system | bool | true | Enable system resource notifications |
| utils.workspaces | bool | true | Enable workspace notifications |
| utils.autoScreenRotation | bool | false | Enable automatic screen rotation (Hyprland only) |

## Notes

- Automatically enables the `notifications` module when active.
- Provides the following CLI scripts: `brightness-control`, `volume-control`, `media-player`, `power-control`, `time-notifier`, `workspace-notifier`, `battery-notifier`, `system-notifier`.
- The `brightness-control` script accepts flags: `-i <amount>` (increase), `-d <amount>` (decrease).
- The `volume-control` script accepts flags: `-i <amount>` (increase), `-d <amount>` (decrease), `-m` (toggle mute).
- The `media-player` script accepts arguments: `play`, `next`, `previous`, `status`.
- The `power-control` script accepts arguments: `suspend`, `hibernate`, `logout`, `reboot`, `shutdown`, `lock`, `menu`, `status`.
- Power actions use window-manager-specific logout commands (e.g., `hyprctl dispatch exit` for Hyprland).
- The `power-control menu` command presents a dmenu-based power options menu (requires the `launcher` module).
- Auto screen rotation uses `iio-sensor-proxy` and only works with Hyprland.
