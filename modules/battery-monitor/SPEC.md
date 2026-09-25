# Battery Monitor

Follows the laptop battery and charger through `upower --monitor` (no polling) and sends desktop notifications for charger connect/disconnect events, low battery, and critical battery levels. Uses upower for battery info and the notifications module for alerts.

## Usage

```nix
my.battery-monitor = {
  enable = true;
  lowThreshold = 20;
  criticalThreshold = 10;
  # Run on AC/battery transitions (and once at session start)
  onBattery = [ "some-command" ];
  onAC = [ "other-command" ];
};
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Enable battery monitoring with notifications |
| lowThreshold | int | 15 | Battery percentage threshold for low battery warning |
| criticalThreshold | int | 5 | Battery percentage threshold for critical battery warning |
| onBattery | list of str | [] | Shell commands run when the session starts on battery or switches to it |
| onAC | list of str | [] | Shell commands run when the session starts on AC or switches to it |

## Notes

- Automatically enables the `notifications` module when active. All notifications share one visual identity from the `battery` category preset: "Battery" header, the battery icon, a charge-level progress bar, and a shared stack tag. Charger connect/disconnect are routine (low urgency); severity is signaled by urgency frame color alone — normal for low battery, critical for the critical threshold.
- Runs as one long-lived user service in the graphical session (`battery-monitor.service`): it checks once at start, then again only when upower reports a change of `battery_BAT*` or `line_power*` (peripheral batteries are ignored). The Hyprland module uses the hooks to turn blur and shadows off on battery.
- Tracks state between checks to avoid duplicate notifications (resets when charger is connected).
- On machines without a battery, the service exits silently.
- Every notification includes the current power draw from upower (`energy-rate`, e.g. `9.6 W`).
