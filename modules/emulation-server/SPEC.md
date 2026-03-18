# Emulation Server

Unified module for hosting ROMs, BIOS files, and save data. The system half (`system.nix`) manages Samba, Syncthing, and WireGuard services. The user half (`user.nix`) creates the directory structure. Enabling the system module auto-enables the user module for the configured user.

## Usage

```nix
# In system config — user module auto-enables for the configured user
emulation-server = {
  enable = true;
  user = "gamer";
  dataDir = "/home/gamer/emulation";
  syncthing.devices = {
    android-phone = {
      id = "XXXXXXX-XXXXXXX-XXXXXXX-XXXXXXX-XXXXXXX-XXXXXXX-XXXXXXX-XXXXXXX";
    };
  };
  wireguard = {
    enable = true;
    privateKeyFile = "/etc/wireguard/private.key";
    peers = [
      {
        publicKey = "client-public-key-here";
        allowedIPs = [ "10.100.0.2/32" ];
      }
    ];
  };
};
```

Override user-side defaults if needed:

```nix
# In user config (usually not needed — auto-enabled from system)
emulation-server.user = {
  systems = [ "snes" "nes" "gba" "nds" "psx" "psp" ];
  standaloneEmulators = [ "retroarch" "ppsspp" ];
};
```

## Options (system)

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Enable the emulation server |
| user | string | "gamer" | User account that owns the emulation data |
| dataDir | path | /home/gamer/emulation | Root directory for emulation data (roms, saves, bios) |
| syncthing.devices | attrset of { id: string } | {} | Syncthing devices to sync saves with |
| wireguard.enable | bool | false | Enable WireGuard VPN for remote emulation access |
| wireguard.listenPort | port | 51820 | UDP port for WireGuard |
| wireguard.address | string | "10.100.0.1/24" | VPN address for this server |
| wireguard.privateKeyFile | path | /etc/wireguard/private.key | Path to the WireGuard private key file |
| wireguard.peers | list of { publicKey, allowedIPs } | [] | WireGuard client peers allowed to connect |

## Options (user — `emulation-server.user.*`)

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false (auto-enabled from system) | Enable directory structure creation |
| dataDir | path | ~/emulation (auto-set from system) | Root emulation directory |
| systems | list of string | (17 systems, see below) | ROM subdirectories to create |
| standaloneEmulators | list of string | ["retroarch" "ppsspp" "duckstation" "dolphin"] | Save subdirectories to create |

### Default systems

snes, nes, gb, gbc, gba, n64, nds, psx, ps2, psp, megadrive, mastersystem, gamecube, wii, dreamcast, saturn, arcade

### Default emulators (save directories)

retroarch (with saves/ and states/ subdirs), ppsspp, duckstation, dolphin

## Notes

### Prerequisites

- The `file-sharing` system module must be available (this module sets `file-sharing.samba` options).
- A dedicated user account (default: `gamer`) must exist to own the emulation data.
- ROMs and BIOS files need to be copied into the directories after setup.

### Directory structure

Created automatically by the user module:

```
emulation/
  roms/{snes,nes,gb,gbc,gba,n64,nds,psx,ps2,psp,megadrive,mastersystem,gamecube,wii,dreamcast,saturn,arcade}/
  saves/{retroarch/{saves,states},ppsspp,duckstation,dolphin}/
  bios/
```

### WireGuard key generation

Generate the server keypair before the first rebuild:

```bash
sudo mkdir -p /etc/wireguard
wg genkey | sudo tee /etc/wireguard/private.key | wg pubkey | sudo tee /etc/wireguard/public.key
sudo chmod 600 /etc/wireguard/private.key
```

For each remote client, generate a keypair on the client side and add its public key to `wireguard.peers`, assigning a unique IP in the `10.100.0.0/24` subnet.

### Samba password

Samba requires a separate password from the system account:

```bash
sudo smbpasswd -a gamer
```

Clients access shares at `smb://<host>/emulation-roms` (LAN) or `smb://10.100.0.1/emulation-roms` (VPN).

### Syncthing device setup

Each client's device ID is visible in the Syncthing web UI at `http://localhost:8384` (Actions > Show ID). Add it to `syncthing.devices`, rebuild, then accept the `emulation-saves` folder share on the client side.

### Firewall

Add Syncthing and WireGuard ports to your firewall configuration:

```nix
firewall = {
  enable = true;
  tcpPorts = [ 22000 ];       # Syncthing transfer
  udpPorts = [ 21027 51820 ]; # Syncthing discovery + WireGuard
};
```

### Verification

After rebuilding, verify all services are running:

```bash
systemctl status syncthing         # Syncthing (web UI at http://localhost:8384)
smbclient -L localhost -U gamer    # Samba shares
sudo wg show                       # WireGuard interface
```

### Android client setup

Android devices do not use NixOS modules but can still connect to the server for save sync and ROM access.

#### Save sync via Syncthing

1. Install **Syncthing** from F-Droid or Play Store
2. Open Syncthing and note your device ID
3. Add the device ID to the server config:
   ```nix
   emulation-server.syncthing.devices = {
     android-phone = { id = "YOUR-DEVICE-ID-HERE"; };
   };
   ```
4. Rebuild the server: `sudo nixos-rebuild switch`
5. On Android Syncthing, add the server as a device using the server's device ID (find it at http://server-ip:8384 > Actions > Show ID)
6. Accept the `emulation-saves` folder share when it appears
7. Set the folder path to `/storage/emulated/0/emulation/saves`
8. Point your Android emulators at this directory for saves

#### ROM access via Samba

Most Android file managers (Solid Explorer, CX File Explorer, etc.) support SMB:

1. Add a network/SMB connection:
   - **Server**: `home-desktop` (LAN) or `10.100.0.1` (VPN)
   - **Share**: `emulation-roms` or `emulation-bios`
   - **Username/Password**: the Samba credentials set with `smbpasswd`
2. Browse and copy ROMs to local storage, or load directly if the emulator supports it

#### Remote access via WireGuard

1. Install **WireGuard** from F-Droid or Play Store
2. Create a new tunnel with this template:
   ```ini
   [Interface]
   PrivateKey = <generate with wg genkey or in the app>
   Address = 10.100.0.3/24
   DNS = 1.1.1.1

   [Peer]
   PublicKey = <server's public key>
   Endpoint = <server public IP or domain>:51820
   AllowedIPs = 10.100.0.0/24
   PersistentKeepalive = 25
   ```
3. Add the Android device's public key to the server config:
   ```nix
   emulation-server.wireguard.peers = [
     {
       publicKey = "android-public-key-here";
       allowedIPs = [ "10.100.0.3/32" ];
     }
   ];
   ```
4. Rebuild the server and activate the tunnel on Android
5. Access Samba shares and Syncthing via the VPN IP `10.100.0.1`
