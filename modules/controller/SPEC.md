# Controller

Provides game controller support: a MangoHud toggle on controller buttons and a Steam-overlay chord for the streamed pad. Monitors controller input events and can send keypresses (e.g., F12 to toggle MangoHud in gamescope) when configured buttons are pressed.

## Usage

```nix
my.controller = {
  enable = true;
  type = "ps5";

  mangohudToggle = {
    enable = true;
    buttons = [ "square" "triangle" ];
    autoStart = true;
  };
};
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Enable controller support and custom mappings |
| type | enum: "ps5", "xbox", "generic" | "ps5" | Type of controller to configure |
| mangohudToggle.enable | bool | true | Enable MangoHud toggle via controller buttons |
| mangohudToggle.buttons | list of enum | ["square" "triangle"] | Controller buttons that trigger MangoHud toggle (square, triangle, circle, x, share, options, l3, r3) |
| mangohudToggle.autoStart | bool | true | Automatically start controller monitoring service |
| steamOverlay.enable | bool | true | Open the Steam overlay from the streamed gamepad via a button chord |
| steamOverlay.buttons | list of enum | ["l3" "r3"] | Chord (held together) that opens the overlay (a, b, x, y, l1, r1, l2, r2, select, start, guide, l3, r3) |
| steamOverlay.holdSeconds | float | 0.2 | How long the chord must be held before firing |
| steamOverlay.padName | string | "Sunshine X-Box One (virtual) pad" | Device name (in `/proc/bus/input/devices`) to watch |

## Notes

- Installs `evtest`, `inotify-tools`, `wtype`, and other dependencies for controller event monitoring.
- The MangoHud toggle service runs as a systemd user service (`controller-mangohud-toggle`) that monitors `/dev/input/` for controller events.
- The service supports hotplug: it waits for controller connection and reconnects automatically if the controller disconnects.
- Button names map to Linux input event codes based on the selected controller type (e.g., PS5 "square" maps to `BTN_WEST`).
- Requires read access to `/dev/input/eventXX` devices (typically via the `input` group).

### Steam overlay chord (`steamOverlay`)

- Over Moonlight there is no keyboard, and **Steam Input is disabled for the Sunshine virtual pad** (so Ryujinx can read it — see `modules/games/SPEC.md`). With Steam Input off, the pad's Guide button can't reach Steam, so the overlay is opened by **injecting its keyboard shortcut (Shift+Tab)** instead — this works regardless of Steam Input, and Switch shortcuts already set `AllowOverlay=1`.
- Runs as a systemd user service (`controller-steam-overlay`) that watches the Sunshine pad's evdev node (hotplug-aware, read-only — no `EVIOCGRAB`) and, on the chord (default **L3+R3**), runs `hyprctl dispatch sendshortcut "SHIFT,TAB,activewindow"`. Same listener pattern as `switch-quit-listener`; the two coexist (distinct chords, no device grab).
- If the overlay doesn't respond to the compositor-injected shortcut, fall back to `wtype -M shift -k Tab -m shift` (set `WAYLAND_DISPLAY`), or `ydotool` (uinput-level, indistinguishable from real hardware) as a last resort.

## Troubleshooting

- The toggle runs as `controller-mangohud-toggle.service` (user unit) from the store; `controller-mangohud-toggle` is also on `PATH` for a manual run.
- Connected controllers: `grep -i controller /proc/bus/input/devices`; raw input: `evtest /dev/input/eventXX`.
- Logs: `journalctl --user -u controller-mangohud-toggle -f`.
