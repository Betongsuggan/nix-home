# Fingerprint

Enables fingerprint authentication via fprintd with support for multiple sensor drivers. TTY login, sudo, su and polkit accept the fingerprint **or** the password at the same prompt, whichever comes first (`pam_fprintd_grosshack`, packaged in `overlays/pam-fprint-grosshack.nix`).

## Usage

```nix
my.fingerprint = {
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

- After enabling, enroll fingerprints with `fprintd-enroll` (one finger per run; `fprintd-enroll -f left-index-finger` for another) and test with `fprintd-verify`.
- The `goodix` and `elan` drivers use TOD (Touch OEM Drivers) packages. Use `generic` for sensors supported by libfprint's built-in drivers; check the sensor's USB id (`lsusb`) against libfprint's `lib/udev/hwdb.d/60-autosuspend-libfprint-2.hwdb` first. Newer Goodix sensors (e.g. `27c6:658c` on bits) are built in, and the Goodix TOD driver doesn't know them.
- PAM: with fprintd on, NixOS gives every PAM service a `pam_fprintd` step that asks for the finger first and only takes the password after a timeout. This module swaps that step's module for grosshack on login, sudo, su and polkit-1 (same slot: `sufficient`, before `pam_unix` with `try_first_pass`, which receives a typed password). hyprlock reads the finger itself over D-Bus while taking the password through PAM, so its PAM stack has no fingerprint step (it would ask twice).
- Never put grosshack on a greetd greeter. It ends the PAM conversation under greetd, which then logs the greeter's pending answer (the typed password) in plain text in the journal (seen with the DMS greeter, 2026-09-26).
- GUI prompts (polkit, e.g. Bitwarden's unlock) need a polkit agent in the session; the window-manager module starts one.

## Clamshell mode

When `clamshellAware = true`, acpid monitors lid events and stops/starts fprintd accordingly. When fprintd is stopped, `pam_fprintd.so` fails immediately and PAM falls through to password authentication — no fingerprint prompt appears.

A oneshot systemd service (`fprintd-lid-check`) also runs at boot to stop fprintd if the lid is already closed when the system starts.

If your hardware uses a different lid state path (e.g. `LID` instead of `LID0`), override `lidStatePath`:

```nix
my.fingerprint = {
  enable = true;
  clamshellAware = true;
  lidStatePath = "/proc/acpi/button/lid/LID/state";
};
```

Check the correct path with: `ls /proc/acpi/button/lid/`
