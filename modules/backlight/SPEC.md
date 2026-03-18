# Backlight

Adds udev rules to allow members of the `video` group to control screen backlight brightness without root privileges.

## Usage

```nix
backlight.enable = true;
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Enable backlight control with proper permissions |

## Notes

- Users must be in the `video` group to adjust brightness.
- The udev rules set group ownership and write permission on `/sys/class/backlight/*/brightness`.
