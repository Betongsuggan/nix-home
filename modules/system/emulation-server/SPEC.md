# Emulation Server

System-level module that runs on the machine hosting ROMs, BIOS files, and save data. Provides Samba (read-only ROM/BIOS shares), Syncthing (bidirectional save sync), and an optional WireGuard VPN for remote access from outside the LAN.

## Usage

```nix
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

## Options

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

## Notes

### Prerequisites

- The `file-sharing` system module must be available (this module sets `file-sharing.samba` options).
- A dedicated user account (default: `gamer`) must exist to own the emulation data.
- ROMs and BIOS files need to be copied into the directories after setup.

### Directory structure

The companion user module (`emulation-server.enable = true` in user config) creates the directory layout:

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
