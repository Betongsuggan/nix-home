# Fingerprint

Enables fingerprint authentication via fprintd with support for multiple sensor drivers. Configures PAM integration for login, sudo, su, and polkit.

## Usage

```nix
fingerprint = {
  enable = true;
  driver = "goodix";
};
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Enable fingerprint reader |
| driver | enum: "goodix" "elan" "generic" | "goodix" | Fingerprint reader driver to use |
| clamshellAware | bool | false | Stop fprintd when lid is closed so auth falls back to password |
| lidStatePath | string | "/proc/acpi/button/lid/LID0/state" | Path to ACPI lid state file |

## Notes

- After enabling, enroll fingerprints with `fprintd-enroll`.
- The `goodix` and `elan` drivers use TOD (Touch OEM Drivers) packages. Use `generic` for sensors supported by libfprint's built-in drivers.
- PAM fingerprint authentication is enabled for login, sudo, su, and polkit-1. Hyprlock uses native D-Bus fprintd integration rather than PAM.

## Clamshell mode

When `clamshellAware = true`, acpid monitors lid events and stops/starts fprintd accordingly. When fprintd is stopped, `pam_fprintd.so` fails immediately and PAM falls through to password authentication — no fingerprint prompt appears.

A oneshot systemd service (`fprintd-lid-check`) also runs at boot to stop fprintd if the lid is already closed when the system starts.

If your hardware uses a different lid state path (e.g. `LID` instead of `LID0`), override `lidStatePath`:

```nix
fingerprint = {
  enable = true;
  clamshellAware = true;
  lidStatePath = "/proc/acpi/button/lid/LID/state";
};
```

Check the correct path with: `ls /proc/acpi/button/lid/`
