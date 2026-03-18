# Secure Boot

Enables UEFI Secure Boot using Lanzaboote, which replaces systemd-boot with signed unified kernel images. Installs `sbctl` for managing Secure Boot keys.

## Usage

```nix
secure-boot.enable = true;
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Enable Secure Boot using Lanzaboote |

## Notes

- Requires `boot.loader.efi.canTouchEfiVariables = true` and a valid EFI system partition mount point.
- Disables both systemd-boot and GRUB; Lanzaboote manages boot entries instead.
- PKI bundle is stored at `/var/lib/sbctl`.
- After first build, complete one-time setup:
  1. `sudo sbctl create-keys`
  2. `sudo sbctl enroll-keys -m`
  3. Reboot and enable Secure Boot in BIOS/UEFI settings
  4. Verify with `sudo sbctl status`
