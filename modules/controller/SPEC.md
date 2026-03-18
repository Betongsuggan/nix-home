# Controller

Provides game controller support with MangoHud toggle via controller buttons, custom button mappings, and LED/rumble settings. Monitors controller input events and can send keypresses (e.g., F12 to toggle MangoHud in gamescope) when configured buttons are pressed.

## Usage

```nix
controller = {
  enable = true;
  type = "ps5";

  mangohudToggle = {
    enable = true;
    buttons = [ "square" "triangle" ];
    autoStart = true;
  };

  customMappings = {
    enable = true;
    mappings = {
      "l3+r3" = "screenshot";
    };
  };

  ledSettings = {
    enable = true;
    color = "blue";
    brightness = 128;
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
| customMappings.enable | bool | false | Enable custom controller button mappings |
| customMappings.mappings | attrsOf string | {} | Custom button combination to command mappings |
| rumble.enable | bool | true | Enable controller rumble/haptic feedback |
| ledSettings.enable | bool | false | Enable custom LED settings for supported controllers |
| ledSettings.color | string | "blue" | LED color for supported controllers |
| ledSettings.brightness | int | 128 | LED brightness (0-255) |

## Notes

- Installs `evtest`, `inotify-tools`, `wtype`, and other dependencies for controller event monitoring.
- The MangoHud toggle service runs as a systemd user service (`controller-mangohud-toggle`) that monitors `/dev/input/` for controller events.
- The service supports hotplug: it waits for controller connection and reconnects automatically if the controller disconnects.
- Button names map to Linux input event codes based on the selected controller type (e.g., PS5 "square" maps to `BTN_WEST`).
- Requires read access to `/dev/input/eventXX` devices (typically via the `input` group).
