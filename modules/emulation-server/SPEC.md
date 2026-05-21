# Emulation Server

Single-file system module for hosting ROMs, BIOS files, and save data. Runs Samba (read-only ROM/BIOS shares via the `file-sharing` module) and Syncthing (bidirectional save sync). Off-LAN access is delegated to Tailscale — the module exposes its ports on the tailnet interface in addition to the configured LAN interface.

## Usage

```nix
emulation-server = {
  enable = true;
  user = "betongsuggan";
  dataDir = "/var/lib/emulation";
  syncthing.devices = {
    android-phone = {
      id = "XXXXXXX-XXXXXXX-XXXXXXX-XXXXXXX-XXXXXXX-XXXXXXX-XXXXXXX-XXXXXXX";
    };
  };
};
```

Override the system/emulator lists if the defaults don't fit:

```nix
emulation-server = {
  enable = true;
  systems = [ "snes" "nes" "gba" "nds" "psx" "psp" ];
  standaloneEmulators = [ "retroarch" "ppsspp" ];
};
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Enable the emulation server |
| user | string | "betongsuggan" | User account that owns the emulation data and runs Syncthing |
| dataDir | path | /var/lib/emulation | Root directory for emulation data (roms, saves, bios) |
| lanInterface | string | "enp1s0" | LAN network interface to open Syncthing/Samba ports on |
| lanSubnet | string | "192.168.50.0/24" | LAN subnet allowed to reach Samba shares |
| systems | list of string | 17 systems (see below) | ROM subdirectories to create |
| standaloneEmulators | list of string | ["retroarch" "ppsspp" "duckstation" "dolphin"] | Save subdirectories to create |
| syncthing.devices | attrset of { id: string } | {} | Syncthing devices to sync saves with |

### Default systems

snes, nes, gb, gbc, gba, n64, nds, psx, ps2, psp, megadrive, mastersystem, gamecube, wii, dreamcast, saturn, arcade

### Default emulators (save directories)

retroarch (with `saves/` and `states/` subdirs), ppsspp, duckstation, dolphin

## Notes

### Prerequisites

- The `file-sharing` system module must be available (this module sets `file-sharing.samba` options).
- The configured user must exist on the host.
- A Tailscale client (`tailscale-client` module) should be enabled on the host if you want off-LAN access; the module opens its ports on `tailscale0` regardless, but the interface only exists once Tailscale is up.
- ROMs and BIOS files need to be copied into the directories after setup.

### Directory structure

Created automatically via `systemd.tmpfiles` at boot, owned by `${user}:users` mode `0775`:

```
${dataDir}/
  roms/{snes,nes,gb,gbc,gba,n64,nds,psx,ps2,psp,megadrive,mastersystem,gamecube,wii,dreamcast,saturn,arcade}/
  saves/{retroarch/{saves,states},ppsspp,duckstation,dolphin}/
  bios/
```

### Network exposure

The module does not touch the general firewall. It opens Syncthing (TCP 22000, UDP 21027) and Samba (TCP 445/139, UDP 137/138) on two interfaces only:

- `lanInterface` (default `enp1s0`) — LAN clients
- `tailscale0` — off-LAN clients via the tailnet

Samba additionally restricts access via `hosts allow` to the LAN subnet plus the Headscale default tailnet CIDR `100.64.0.0/10`.

### Samba password

Samba requires a separate password from the system account:

```bash
sudo smbpasswd -a betongsuggan
```

Clients access shares at `smb://<host>/emulation-roms` (LAN/tailnet).

### Syncthing device setup

Each client's device ID is visible in its Syncthing web UI at `http://localhost:8384` (Actions > Show ID). Add it to `syncthing.devices`, rebuild, then accept the `emulation-saves` folder share on the client side.

### Verification

```bash
systemctl status syncthing         # Syncthing (web UI at http://localhost:8384)
smbclient -L localhost -U betongsuggan
sudo ss -tlnp | grep -E ':(22000|445|139)'
```

### Android client setup

Android devices don't run NixOS modules but can still join the save-sync mesh.

#### Save sync via Syncthing

1. Install **Syncthing** from F-Droid or Play Store.
2. Open Syncthing and note your device ID.
3. Add the device ID to the server config:
   ```nix
   emulation-server.syncthing.devices = {
     android-phone = { id = "YOUR-DEVICE-ID-HERE"; };
   };
   ```
4. Rebuild the server.
5. On Android, add the server as a device using the server's device ID (find it at `http://server:8384` > Actions > Show ID).
6. Accept the `emulation-saves` folder share. Point it at `/storage/emulated/0/emulation/saves`.

#### ROM access via Samba

Most Android file managers (Solid Explorer, CX File Explorer, etc.) support SMB. Connect to `<server>/emulation-roms` or `<server>/emulation-bios` using the Samba password.

#### Off-LAN access

Install the **Tailscale** app, sign in against the Headscale coordinator, and use the server's tailnet hostname / IP. No separate tunnel needed.
