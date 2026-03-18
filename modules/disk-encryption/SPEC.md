# Disk Encryption

Configures LUKS disk encryption with a detached header for the root partition. The encrypted device is unlocked during early boot (initrd) before LVM activation.

## Usage

```nix
diskEncryption = {
  enable = true;
  diskId = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx";
  headerId = "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy";
};
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Enable disk encryption |
| diskId | string | (required) | PARTUUID of the LUKS-encrypted partition |
| headerId | string | (required) | PARTUUID of the partition containing the detached LUKS header |

## Notes

- Uses `/dev/disk/by-partuuid/` for stable device identification.
- Enables `allowDiscards` (TRIM support for SSDs) and `preLVM` (unlock before LVM).
- The detached header means the encrypted partition itself has no visible LUKS signature, providing plausible deniability.
