# Emulation Client

User-level module for NixOS machines that connect to the emulation server. Enables Syncthing for save file synchronization and provides a helper script for mounting ROM/BIOS Samba shares.

## Usage

```nix
emulation-client = {
  enable = true;
  server.address = "home-desktop";
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

- A running emulation server (see `modules/system/emulation-server/`)
- The server's Syncthing device ID and Samba password
- For remote access: WireGuard configured on both server and client

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
# Uses the configured server address (default: home-desktop)
mount-emulation-roms

# Override server address (e.g. via VPN)
mount-emulation-roms 10.100.0.1

# Override both server and username
mount-emulation-roms 10.100.0.1 gamer
```

This mounts read-only Samba shares at `~/emulation/roms` and `~/emulation/bios`. You will be prompted for the Samba password (set on the server with `smbpasswd`).

To unmount:

```bash
sudo umount ~/emulation/roms ~/emulation/bios
```

### WireGuard (remote access)

For access outside the LAN, set up WireGuard on the client.

Generate a keypair:

```bash
wg genkey | tee ~/wireguard-private.key | wg pubkey > ~/wireguard-public.key
```

Add WireGuard configuration to your system config:

```nix
networking.wireguard.interfaces.wg0 = {
  ips = [ "10.100.0.2/24" ];
  privateKeyFile = "/path/to/wireguard-private.key";
  peers = [
    {
      publicKey = "server-public-key-here";
      endpoint = "your-server-public-ip:51820";
      allowedIPs = [ "10.100.0.0/24" ];
      persistentKeepalive = 25;
    }
  ];
};
```

Add your client's public key to the server's `wireguard.peers` config and rebuild the server. Once connected, use the VPN IP for Samba: `mount-emulation-roms 10.100.0.1`

### Pointing emulators at the save directory

Configure each emulator to use `~/emulation/saves/<emulator>/` for saves:

- **RetroArch**: Settings > Directory > Savefile = `~/emulation/saves/retroarch/saves`, Savestate = `~/emulation/saves/retroarch/states`
- **PPSSPP**: Settings > System > Save path = `~/emulation/saves/ppsspp`
- **Duckstation**: Settings > Memory Cards directory = `~/emulation/saves/duckstation`
- **Dolphin**: Config > Paths > Wii NAND Root / GC Memory Cards = `~/emulation/saves/dolphin`
