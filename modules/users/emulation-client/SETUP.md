# Emulation Client Setup (NixOS)

User-level module for NixOS machines that connect to the emulation server.
Enables Syncthing for save synchronization and provides a helper script
for mounting ROM/BIOS Samba shares.

## Prerequisites

- A running emulation server (see `modules/system/emulation-server/SETUP.md`)
- The server's Syncthing device ID and Samba password
- For remote access: WireGuard configured on both server and client

## 1. Enable the module

In your user config (e.g. `user-betongsuggan.nix` on private-laptop):

```nix
emulation-client = {
  enable = true;
  server.address = "home-desktop";  # Hostname or IP of the server
};
```

This will:
- Enable the Syncthing user service for save file synchronization
- Install `cifs-utils` for Samba mounting
- Add the `mount-emulation-roms` helper script to your PATH
- Create `~/emulation/saves/` with subdirectories matching the server layout

## 2. Rebuild

```bash
sudo nixos-rebuild switch
# or: home-manager switch (if using standalone home-manager)
```

## 3. Connect Syncthing

Open the Syncthing web UI:

```bash
xdg-open http://localhost:8384
```

1. Go to **Actions > Show ID** and copy your device ID
2. Add this device ID to the server's `syncthing.devices` config and rebuild the server
3. On the server's Syncthing web UI, share the `emulation-saves` folder with your device
4. Accept the folder share on your client's Syncthing web UI
5. Set the folder path to `~/emulation/saves`

Saves will now sync bidirectionally. Changes made offline sync automatically when
the devices reconnect.

## 4. Mount ROM and BIOS shares

Use the included helper script:

```bash
# Uses the configured server address (default: home-desktop)
mount-emulation-roms

# Override server address (e.g. via VPN)
mount-emulation-roms 10.100.0.1

# Override both server and username
mount-emulation-roms 10.100.0.1 gamer
```

This mounts read-only Samba shares at `~/emulation/roms` and `~/emulation/bios`.
You'll be prompted for the Samba password (set on the server with `smbpasswd`).

To unmount:

```bash
sudo umount ~/emulation/roms ~/emulation/bios
```

## 5. WireGuard (remote access)

For access outside the LAN, set up WireGuard on the client.

Generate a keypair:

```bash
wg genkey | tee ~/wireguard-private.key | wg pubkey > ~/wireguard-public.key
```

Add WireGuard configuration to your system config:

```nix
networking.wireguard.interfaces.wg0 = {
  ips = [ "10.100.0.2/24" ];  # Unique IP in the VPN subnet
  privateKeyFile = "/path/to/wireguard-private.key";
  peers = [
    {
      publicKey = "server-public-key-here";
      endpoint = "your-server-public-ip:51820";
      allowedIPs = [ "10.100.0.0/24" ];
      persistentKeepalive = 25;  # Keeps NAT mappings alive
    }
  ];
};
```

Add your client's public key to the server's `wireguard.peers` config and rebuild
the server.

Once connected, use the VPN IP for Samba: `mount-emulation-roms 10.100.0.1`

## 6. Point emulators at the save directory

Configure each emulator to use `~/emulation/saves/<emulator>/` for saves:

- **RetroArch**: Settings > Directory > Savefile = `~/emulation/saves/retroarch/saves`,
  Savestate = `~/emulation/saves/retroarch/states`
- **PPSSPP**: Settings > System > Save path = `~/emulation/saves/ppsspp`
- **Duckstation**: Settings > Memory Cards directory = `~/emulation/saves/duckstation`
- **Dolphin**: Config > Paths > Wii NAND Root / GC Memory Cards = `~/emulation/saves/dolphin`

## Module options reference

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enable` | bool | false | Enable emulation client |
| `savesDir` | path | ~/emulation/saves | Local save sync directory |
| `server.address` | string | "home-desktop" | Server hostname or IP |
| `standaloneEmulators` | list | [retroarch ppsspp duckstation dolphin] | Emulators to create save dirs for |
