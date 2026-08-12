# Battery Monitor

Periodically monitors battery status via a systemd timer and sends desktop notifications for charger connect/disconnect events, low battery, and critical battery levels. Uses upower for battery info and the notifications module for alerts.

## Usage

```nix
battery-monitor = {
  enable = true;
  lowThreshold = 20;
  criticalThreshold = 10;
  checkInterval = "2min";
};
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Enable battery monitoring with notifications |
| lowThreshold | int | 15 | Battery percentage threshold for low battery warning |
| criticalThreshold | int | 5 | Battery percentage threshold for critical battery warning |
| checkInterval | string | "1min" | How often to check battery status (systemd time format) |

## Notes

- Automatically enables the `notifications` module when active. All notifications share one visual identity from the `battery` category preset: "Battery" header, the battery icon, a charge-level progress bar, and a shared stack tag. Charger connect/disconnect are routine (low urgency); severity is signaled by urgency frame color alone — normal for low battery, critical for the critical threshold.
- Runs as a systemd user timer (`battery-monitor.timer`) and oneshot service (`battery-monitor.service`).
- Tracks state between checks to avoid duplicate notifications (resets when charger is connected).
- On machines without a battery, the service exits silently.
