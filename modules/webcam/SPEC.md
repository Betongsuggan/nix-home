# Webcam Settings Module

Persists per-camera V4L2 control settings across reboots and USB reconnects. A udev rule fires `v4l2-ctl --set-ctrl` whenever a matching video4linux device node appears, so settings are applied both at boot and on every plug-in.

Also installs `cameractrls-gtk4` for interactive discovery and adjustment of controls.

## Usage

```nix
webcam = {
  enable = true;
  cameras = [
    {
      name      = "mx-brio";   # used in generated script name
      vendorId  = "046d";      # Logitech USB vendor ID
      productId = "085b";      # MX Brio 4K — verify with: lsusb | grep -i logitech
      settings  = {
        brightness                     = 128;
        contrast                       = 128;
        saturation                     = 128;
        sharpness                      = 128;
        white_balance_temperature_auto = 1;
        focus_automatic_continuous     = 1;
      };
    }
  ];
};
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Enable webcam settings management |
| cameras | list of submodule | [] | Cameras to configure |
| cameras.\*.name | string | — | Identifier (no spaces), used in the udev script name |
| cameras.\*.vendorId | string or null | null | USB vendor ID (4 hex digits). Null matches any vendor |
| cameras.\*.productId | string or null | null | USB product ID (4 hex digits). Null matches any product |
| cameras.\*.settings | attrs of int | {} | V4L2 control name → integer value. Empty means no udev rule is generated |

## Discovering your camera's USB IDs

```sh
lsusb | grep -i logitech
# Bus 003 Device 004: ID 046d:085b Logitech, Inc. MX Brio
#                        ^^^^ ^^^^
#                        vendorId productId
```

## Listing available V4L2 controls

```sh
# List all controls with current values and valid range
v4l2-ctl --list-ctrls-menus

# For a specific device node
v4l2-ctl --device=/dev/video0 --list-ctrls-menus
```

Use the `cameractrls` GUI to adjust controls interactively and observe their names and value ranges before declaring them in Nix.

## Finding the correct /dev/video node

```sh
v4l2-ctl --list-devices
```

The primary capture node always has `index 0` in sysfs. The udev rule uses `ATTR{index}=="0"` to target it specifically and avoid firing on the metadata node (which also appears as a `video4linux` device with the same USB IDs).

## How persistence works

For each camera entry with non-empty `settings`, a `pkgs.writeShellScript` is generated containing a `v4l2-ctl --set-ctrl` call with all declared controls. A udev rule with `ACTION=="add", SUBSYSTEM=="video4linux"` triggers this script (passing the kernel device name as `$1`) whenever the device node appears — both at boot and on every plug-in.

Cameras with `settings = {}` produce no udev rule; they are effectively ignored until settings are populated.
