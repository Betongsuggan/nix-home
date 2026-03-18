# File Manager

Installs the Thunar file manager with plugins and enables supporting system services: GVFS (virtual filesystem), Tumbler (thumbnails), udisks2 (disk management), and Polkit (privileged operations).

## Usage

```nix
fileManagerSystem = {
  enable = true;
  enableGvfs = true;
  enableTumbler = true;
  enableUdisks = true;
};
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Enable file manager system services |
| enableGvfs | bool | true | Enable GVFS for virtual filesystem support (trash, MTP, SMB, SFTP) |
| enableTumbler | bool | true | Enable Tumbler thumbnail service |
| enableUdisks | bool | true | Enable udisks2 for disk management and auto-mounting |

## Notes

- Installs Thunar with the archive plugin and volume manager plugin.
- Enables `xfconf` as the settings backend for Thunar/XFCE applications.
- Polkit is always enabled when this module is active, to support privileged mount operations.
