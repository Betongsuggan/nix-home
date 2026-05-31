# Emulation Client

User-level module for NixOS machines that connect to the emulation server. Enables Syncthing for save file synchronization and provides a helper script for mounting ROM/BIOS Samba shares.

## Usage

```nix
emulation-client = {
  enable = true;
  server.address = "192.168.50.5";  # controller's LAN IP, or tailnet hostname
};
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Enable emulation client (save sync + ROM access) |
| savesDir | path | ~/emulation/saves | Local directory for synced save files |
| server.address | string | "home-desktop" | Address of the emulation server (hostname or IP) |
| standaloneEmulators | list of string | ["retroarch" "ppsspp" "duckstation" "dolphin"] | Standalone emulators to create save subdirectories for |

## Notes

### Prerequisites

- A running emulation server (see `modules/emulation-server/`)
- The server's Syncthing device ID (for save sync pairing; Samba is anonymous, no credential needed)
- For off-LAN access: Tailscale on both ends (server reachable via its tailnet hostname / IP)

### What enabling this module does

- Enables the Syncthing user service for save file synchronization
- Installs `cifs-utils` for Samba mounting
- Adds the `mount-emulation-roms` helper script to your PATH
- Creates `~/emulation/saves/` with subdirectories matching the server layout

### Connecting Syncthing

1. Open the Syncthing web UI: `xdg-open http://localhost:8384`
2. Go to **Actions > Show ID** and copy your device ID
3. Add this device ID to the server's `syncthing.devices` config and rebuild the server
4. On the server's Syncthing web UI, share the `emulation-saves` folder with your device
5. Accept the folder share on your client's Syncthing web UI
6. Set the folder path to `~/emulation/saves`

Saves sync bidirectionally. Changes made offline sync automatically when devices reconnect.

### Mounting ROM and BIOS shares

Use the included helper script:

```bash
# Uses the configured server address
mount-emulation-roms

# Override server address (e.g. tailnet hostname)
mount-emulation-roms controller
```

This mounts the Samba shares at `~/emulation/roms` and `~/emulation/bios`. The mount uses anonymous (guest) auth — no password prompt. The shares are **writable** (you can drop new ROMs / BIOS files in via the mount) but with server-side delete protection: any deletes through the mount are transparently moved to a hidden `.recycle/` directory on the server rather than actually unlinked. See `modules/emulation-server/SPEC.md` for the operator-side recycle hygiene.

To unmount:

```bash
sudo umount ~/emulation/roms ~/emulation/bios
```

### Off-LAN access

The server exposes Syncthing and Samba on its `tailscale0` interface as well as the LAN. To use the server while away from home, enable the `tailscale-client` module on this host and pass the server's tailnet hostname as `server.address` (or run `mount-emulation-roms <tailnet-hostname>` ad-hoc).

### Pointing emulators at the save directory

Configure each emulator to use `~/emulation/saves/<emulator>/` for saves:

- **RetroArch**: Settings > Directory > Savefile = `~/emulation/saves/retroarch/saves`, Savestate = `~/emulation/saves/retroarch/states`
- **PPSSPP**: Settings > System > Save path = `~/emulation/saves/ppsspp`
- **Duckstation**: Settings > Memory Cards directory = `~/emulation/saves/duckstation`
- **Dolphin**: Config > Paths > Wii NAND Root / GC Memory Cards = `~/emulation/saves/dolphin`
