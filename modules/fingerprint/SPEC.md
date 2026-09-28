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

## Notes

- After enabling, enroll fingerprints with `fprintd-enroll` (one finger per run; `fprintd-enroll -f left-index-finger` for another) and test with `fprintd-verify`.
- The `goodix` and `elan` drivers use TOD (Touch OEM Drivers) packages. Use `generic` for sensors supported by libfprint's built-in drivers; check the sensor's USB id (`lsusb`) against libfprint's `lib/udev/hwdb.d/60-autosuspend-libfprint-2.hwdb` first. Newer Goodix sensors (e.g. `27c6:658c` on bits) are built in, and the Goodix TOD driver doesn't know them.
- PAM: with fprintd on, NixOS gives every PAM service a `pam_fprintd` step that asks for the finger first and only takes the password after a timeout. This module swaps that step's module for grosshack on login, sudo, su and polkit-1 (same slot: `sufficient`, before `pam_unix` with `try_first_pass`, which receives a typed password). hyprlock reads the finger itself over D-Bus while taking the password through PAM, so its PAM stack has no fingerprint step (it would ask twice).
- Never put grosshack on a greetd greeter. It ends the PAM conversation under greetd, which then logs the greeter's pending answer (the typed password) in plain text in the journal (seen with the DMS greeter, 2026-09-26).
- GUI prompts (polkit, e.g. Bitwarden's unlock) need a polkit agent in the session; the window-manager module starts one.

- No clamshell mode: with the lid closed the password is typed at the same prompt. Stopping fprintd on lid events (the removed `clamshellAware`) broke hyprlock, whose device claim died with the restarted daemon when resume replayed the lid close/open events, so fingerprint unlock failed until a password unlock.
