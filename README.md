# NixOS Configuration

Personal NixOS configuration flake managing multiple hosts and users.

## Hosts

- **bits** - NixOS laptop with disk encryption
- **private-laptop** - Private laptop configuration
- **private-desktop** - Gaming desktop with AMD GPU

## Features

### System Modules
- Graphics (AMD/Intel support)
- Audio (PipeWire)
- Bluetooth with wake-on-bluetooth
- Disk encryption (LUKS)
- Secure Boot (opt-in)
- Power management
- Networking with NetworkManager
- Docker
- Printers
- Touchpad configuration
- Undervolting

### User Modules
- Window managers (Sway, Hyprland, i3)
- Launchers (Walker, Rofi, Wofi)
- Terminals (Alacritty)
- Shell (Bash, Fish, Nushell)
- Development tools
- Gaming configuration

## Secure Boot Setup

Secure Boot is available as an opt-in feature for any host. To enable:

### 1. Enable in Host Configuration

Add to your host's `system.nix`:

```nix
secure-boot.enable = true;
```

### 2. Build and Switch

```bash
sudo nixos-rebuild switch --flake .#<hostname>
```

Note: This will automatically disable GRUB and enable systemd-boot. You can still select NixOS generations by pressing **Space** during boot.

### 3. One-Time Setup (Per Machine)

After rebuilding, complete these steps once per machine:

#### Create Secure Boot Keys
```bash
sudo sbctl create-keys
```

#### Enroll Keys in Firmware
This command enrolls your keys and enables Secure Boot:
```bash
sudo sbctl enroll-keys -m
```

The `-m` flag includes Microsoft keys, which allows dual-booting with Windows.

#### Verify Signed Files
Check that unified kernel images were created:
```bash
ls /boot/EFI/Linux/
```

You should see `*.efi` files for each generation.

#### Enable Secure Boot in BIOS/UEFI
1. Reboot your system
2. Enter BIOS/UEFI settings (usually Del, F2, or F12)
3. Navigate to Secure Boot settings
4. Enable Secure Boot
5. Save and exit

#### Verify Secure Boot Status
After rebooting with Secure Boot enabled:
```bash
sudo sbctl status
```

Expected output:
```
Installed:      ✓ sbctl is installed
Setup Mode:     ✓ Disabled
Secure Boot:    ✓ Enabled
```

### Troubleshooting

**System won't boot after enabling Secure Boot:**
- Disable Secure Boot in BIOS temporarily
- Boot into NixOS
- Run `sudo sbctl verify` to check what's not signed
- Rebuild the system: `sudo nixos-rebuild switch --flake .#<hostname>`
- Re-enable Secure Boot in BIOS

**Dual-boot with Windows:**
- Use `sbctl enroll-keys -m` to include Microsoft keys
- This allows Windows to boot alongside NixOS

**Custom kernel modules:**
- Extra modules (like `ryzen-smu`) are automatically signed by lanzaboote
- No additional configuration needed

## Building Configurations

### NixOS System
```bash
sudo nixos-rebuild switch --flake .#<hostname>
```

### Home Manager
```bash
home-manager switch --flake .#<user>@<hostname>
```

## Structure

```
.
├── flake.nix              # Main flake configuration
├── hosts/                 # Host-specific configurations
│   ├── bits/
│   ├── private-laptop/
│   └── private-desktop/
├── modules/
│   ├── common/           # Shared between system and user
│   ├── system/           # System-level modules
│   └── users/            # User-level modules
└── overrides/            # Package overrides
```
