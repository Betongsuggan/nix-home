# Emulation Server Setup

System-level module that runs on the machine hosting ROMs, BIOS files, and save data.
Provides Samba (read-only ROM/BIOS shares), Syncthing (bidirectional save sync),
and WireGuard VPN (remote access from outside LAN).

## Prerequisites

- A NixOS machine with the `file-sharing` and `firewall` system modules available
- A dedicated user account (default: `gamer`) that will own the emulation data
- ROMs and BIOS files to populate the directories after setup

## 1. Enable the module

In your host's `system.nix`:

```nix
emulation-server = {
  enable = true;
  user = "gamer";
  dataDir = "/home/gamer/emulation";
  syncthing.devices = { };  # Populated in step 4
  wireguard = {
    enable = true;
    privateKeyFile = "/etc/wireguard/private.key";
    peers = [ ];  # Populated in step 5
  };
};
```

Add Syncthing and WireGuard ports to your firewall config:

```nix
firewall = {
  enable = true;
  tcpPorts = [ 22000 ];       # Syncthing transfer
  udpPorts = [ 21027 51820 ]; # Syncthing discovery + WireGuard
};
```

## 2. Enable the user module

In the corresponding user config (e.g. `user-gamer.nix`), enable the user-side
module that creates the directory structure:

```nix
emulation-server.enable = true;
```

This creates the full EmulationStation-compatible layout under `~/emulation/`:

```
emulation/
├── roms/{snes,nes,gb,gbc,gba,n64,nds,psx,ps2,psp,megadrive,mastersystem,gamecube,wii,dreamcast,saturn,arcade}/
├── saves/{retroarch/{saves,states},ppsspp,duckstation,dolphin}/
└── bios/
```

To customize which systems get ROM directories or which emulators get save dirs:

```nix
emulation-server = {
  enable = true;
  systems = [ "snes" "nes" "gba" "psx" ];  # Only create these ROM dirs
  standaloneEmulators = [ "retroarch" "duckstation" ];  # Only these save dirs
};
```

## 3. Generate WireGuard keys

Before rebuilding, generate the server's WireGuard keypair:

```bash
sudo mkdir -p /etc/wireguard
wg genkey | sudo tee /etc/wireguard/private.key | wg pubkey | sudo tee /etc/wireguard/public.key
sudo chmod 600 /etc/wireguard/private.key
```

Save the public key output -- clients will need it to connect.

## 4. Rebuild and verify

```bash
sudo nixos-rebuild switch
```

Verify all services are running:

```bash
# Directories created
ls ~/emulation/{roms,saves,bios}

# Syncthing running
systemctl status syncthing
# Web UI at http://localhost:8384

# Samba shares visible
smbclient -L localhost -U gamer

# WireGuard interface up
sudo wg show
```

## 5. Set a Samba password

Samba requires a separate password from the system account:

```bash
sudo smbpasswd -a gamer
```

Clients will use this password when mounting ROM/BIOS shares.

## 6. Add Syncthing devices

When a client device sets up Syncthing, it will have a device ID visible in its
Syncthing web UI (http://localhost:8384 -> Actions -> Show ID).

Add each device to the server config:

```nix
emulation-server.syncthing.devices = {
  android-phone = {
    id = "XXXXXXX-XXXXXXX-XXXXXXX-XXXXXXX-XXXXXXX-XXXXXXX-XXXXXXX-XXXXXXX";
  };
  private-laptop = {
    id = "YYYYYYY-YYYYYYY-YYYYYYY-YYYYYYY-YYYYYYY-YYYYYYY-YYYYYYY-YYYYYYY";
  };
};
```

Then rebuild. The server will share the `emulation-saves` folder with those devices.

On each client, accept the folder share via the Syncthing web UI or configure it
declaratively (see the client module docs).

## 7. Add WireGuard peers

For each remote client, generate a keypair on the client side:

```bash
wg genkey | tee private.key | wg pubkey > public.key
```

Then add the client's public key to the server config, assigning it a unique IP
in the `10.100.0.0/24` subnet:

```nix
emulation-server.wireguard.peers = [
  {
    publicKey = "client-public-key-here";
    allowedIPs = [ "10.100.0.2/32" ];
  }
  {
    publicKey = "another-client-public-key";
    allowedIPs = [ "10.100.0.3/32" ];
  }
];
```

Rebuild after adding peers. Clients connect using the server's public key and
endpoint (your public IP or dynamic DNS on port 51820).

## Populating ROMs and BIOS

After setup, copy your ROM files into the appropriate system directories:

```bash
cp ~/Downloads/game.sfc ~/emulation/roms/snes/
cp ~/Downloads/scph1001.bin ~/emulation/bios/
```

Clients access these via Samba: `smb://home-desktop/emulation-roms` (LAN) or
`smb://10.100.0.1/emulation-roms` (VPN).

## Module options reference

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enable` | bool | false | Enable the emulation server |
| `user` | string | "gamer" | User that owns emulation data |
| `dataDir` | path | /home/gamer/emulation | Root data directory |
| `syncthing.devices` | attrset | {} | Syncthing device IDs to sync with |
| `wireguard.enable` | bool | false | Enable WireGuard VPN |
| `wireguard.listenPort` | port | 51820 | WireGuard UDP port |
| `wireguard.address` | string | "10.100.0.1/24" | Server VPN address |
| `wireguard.privateKeyFile` | path | /etc/wireguard/private.key | Path to WG private key |
| `wireguard.peers` | list | [] | WireGuard client peers |
