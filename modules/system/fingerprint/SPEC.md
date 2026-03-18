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

## Notes

- After enabling, enroll fingerprints with `fprintd-enroll`.
- The `goodix` and `elan` drivers use TOD (Touch OEM Drivers) packages. Use `generic` for sensors supported by libfprint's built-in drivers.
- PAM fingerprint authentication is enabled for login, sudo, su, and polkit-1. Hyprlock uses native D-Bus fprintd integration rather than PAM.
