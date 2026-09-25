# Secure Boot

Enables UEFI Secure Boot using Lanzaboote, which replaces systemd-boot with signed unified kernel images. Installs `sbctl` for managing Secure Boot keys.

## Usage

```nix
my.secure-boot.enable = true;
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Enable Secure Boot using Lanzaboote |

## Notes

- Requires `boot.loader.efi.canTouchEfiVariables = true` and a valid EFI system partition mount point.
- Disables both systemd-boot and GRUB; Lanzaboote manages boot entries instead. The host's `boot.loader.systemd-boot.configurationLimit` is carried over to `boot.lanzaboote.configurationLimit`.
- PKI bundle is stored at `/var/lib/sbctl`.
- After first build, complete one-time setup:
  1. `sudo sbctl create-keys`
  2. `sudo sbctl enroll-keys -m`
  3. Reboot and enable Secure Boot in BIOS/UEFI settings
  4. Verify with `sudo sbctl status`
- `-m` in `enroll-keys` also enrolls Microsoft's keys, which keeps Windows dual-boot working.
- Extra kernel modules (e.g. `ryzen-smu`) are signed by lanzaboote automatically.

## Troubleshooting

If the machine won't boot after enabling Secure Boot: turn Secure Boot off in the firmware, boot NixOS, run `sudo sbctl verify` to see what is unsigned, rebuild (`sudo nixos-rebuild switch --flake .#<host>`), and turn it back on.
