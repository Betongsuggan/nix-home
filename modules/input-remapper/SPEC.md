# Input Remapper

Declarative key remapping via input-remapper. This is a system-level module that enables the `services.input-remapper` daemon, builds the config tree (`config.json` + `presets/<device>/<preset>.json`) as a single store path exposed at `/etc/input-remapper-2`, points the daemon at it over D-Bus when the service starts, and auto-applies presets when devices are connected (via udev hotplug rules). No per-user setup is needed; remapping is identical for every user session on the host.

## Usage

In your host's `system.nix`:

```nix
my.input-remapper = {
  enable = true;
  devices."Logitech G13 Gaming Keypad" = {
    preset = "gaming";
    mappings = [
      { input = [{ type = 1; code = 656; }]; output = "KEY_1"; }  # G1 -> 1
      { input = [{ type = 1; code = 657; }]; output = "KEY_2"; }  # G2 -> 2
    ];
  };
};
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Enable input-remapper declarative configuration |
| devices | attrsOf deviceType | {} | Devices to configure, keyed by evdev device name |

### Device options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| preset | string | "default" | Preset name for this device |
| mappings | listOf mappingType | [] | Key mappings for this device |

### Mapping options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| input | listOf inputEventType | (required) | Input event combination |
| output | string | (required) | Output symbol (e.g. `KEY_1`) or macro (e.g. `key(KEY_LEFTCTRL + KEY_C)`) |
| target | enum | "keyboard" | One of: `keyboard`, `mouse`, `gamepad`, `keyboard + mouse` |
| macroKeySleepMs | int or null | null | Pause between a macro's key events in ms (input-remapper's `macro_key_sleep_ms`; its default is 0, i.e. back to back) |

### Input event options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| type | int | (required) | evdev event type (1=EV_KEY, 2=EV_REL, 3=EV_ABS) |
| code | int | (required) | evdev event code |
| origin_hash | string or null | null | Device origin hash for disambiguation |
| analog_threshold | int or null | null | Axis threshold percentage (-100 to 100) for analog-to-digital mapping |

## Logitech G13 Key Code Reference

The G13 kernel driver (`hid-lg-g15`) exposes keys as `KEY_MACRO` codes:

| G-Key | evdev code | Kernel symbol |
|-------|-----------|---------------|
| G1    | 656       | KEY_MACRO1    |
| G2    | 657       | KEY_MACRO2    |
| G3    | 658       | KEY_MACRO3    |
| G4    | 659       | KEY_MACRO4    |
| G5    | 660       | KEY_MACRO5    |
| G6    | 661       | KEY_MACRO6    |
| G7    | 662       | KEY_MACRO7    |
| G8    | 663       | KEY_MACRO8    |
| G9    | 664       | KEY_MACRO9    |
| G10   | 665       | KEY_MACRO10   |
| G11   | 666       | KEY_MACRO11   |
| G12   | 667       | KEY_MACRO12   |
| G13   | 668       | KEY_MACRO13   |
| G14   | 669       | KEY_MACRO14   |
| G15   | 670       | KEY_MACRO15   |
| G16   | 671       | KEY_MACRO16   |
| G17   | 672       | KEY_MACRO17   |
| G18   | 673       | KEY_MACRO18   |
| G19   | 674       | KEY_MACRO19   |
| G20   | 675       | KEY_MACRO20   |
| G21   | 676       | KEY_MACRO21   |
| G22   | 677       | KEY_MACRO22   |

The M keys and the LCD keys are keys too (no layers: input-remapper has none and the driver switches nothing):

| Key | evdev code | Kernel symbol |
|-----|-----------|---------------|
| M1 | 691 | KEY_MACRO_PRESET1 |
| M2 | 692 | KEY_MACRO_PRESET2 |
| M3 | 693 | KEY_MACRO_PRESET3 |
| MR | 688 | KEY_MACRO_RECORD_START |
| LCD keys | 696-700 | KEY_KBD_LCD_MENU1-5 |
| Backlight | 542 | KEY_LIGHTS_TOGGLE |

### G13 Special Keys

| Key | evdev code | Kernel symbol |
|-----|-----------|---------------|
| M1/M2/M3 cycle | 691 | KEY_MACRO_PRESET_CYCLE |
| MR (record) | 692 | KEY_MACRO_RECORD_START |

### G13 Thumbstick

Exposed as a separate evdev device ("Logitech G13 Thumbstick"):
- X axis: type=3, code=0 (`ABS_X`), range 0-255
- Y axis: type=3, code=1 (`ABS_Y`), range 0-255

## Discovering Device Names

Run `evtest` and press a key on the device to find its evdev name, or use:
```bash
cat /proc/bus/input/devices | grep -A 3 "G13"
```

## Notes

- Device names in preset paths are sanitized: `/\?%*:|"<>` become `_`
- The system service is wanted by `multi-user.target` (not the nixpkgs default `graphical.target`): hosts without a display manager (getty autologin + compositor started from the shell, like `desktop`) never reach `graphical.target`, so the daemon would never start and hotplugged devices would not be remapped. The daemon is a root-level uinput injector and needs no graphical session
- Config is handed to the daemon over D-Bus, not discovered from a home directory: input-remapper's root daemon deliberately loads nothing on its own and waits for a *user session* to call `set_config_dir` (upstream does this from an XDG autostart entry). Root-run callers such as the udev hook are skipped by that logic, so a config under `/root/.config` (the previous design of this module) was never read and every autoload was rejected with "before a user told the service about their session". The module's `postStart` calls `set_config_dir /etc/input-remapper-2` and then `autoload` via `busctl`; from that point the udev rule's per-device `autoload_single` works for hotplug. Hosts migrated from the old design may still have dead symlinks under `/root/.config/input-remapper-2`, which can be deleted
- Changing mappings restarts the daemon on rebuild (`restartTriggers` on the config tree), so the new preset is injected without a reboot or replug
- Hotplug troubleshooting: `systemctl status input-remapper` must be `active`. If udev logs `input-remapper-control ... failed with exit code 5`, the daemon is not running ("Daemon missing"). If the daemon logs "Request to autoload ... before a user told the service about their session", `set_config_dir` was not called; check `journalctl -u input-remapper` for the `postStart` `busctl` calls. A working injection shows `input-remapper <device> forwarded` entries in `/proc/bus/input/devices`. Exit code 2 on `--device ''` lines is harmless noise from parent `inputNN` nodes that have no `DEVNAME`
- Udev rules trigger autoload when devices are hotplugged
- Output symbols are evdev key names, i.e. physical key positions, not letters in the user's layout. On a non-QWERTY compositor layout the mapped keys come out translated (Colemak: `KEY_W/A/S/D` -> "wars") unless the compositor gives the daemon's virtual keyboard a plain US layout. The hyprland window-manager backend does this with `device` blocks for `input-remapper-keyboard`; see `modules/window-manager/SPEC.md`
- Input combinations (multiple simultaneous keys) are supported via multiple entries in `input`
