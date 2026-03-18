# Emulation Server

User-level module that creates the emulation directory structure on the server machine. Intended for the user account that Syncthing and Samba run as. This module is separate from the system module because it uses Home Manager's `home.activation` to create directories owned by the user, while the system module handles service configuration.

## Usage

```nix
emulation-server.enable = true;
```

Override the default lists to match your collection:

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
| enable | bool | false | Enable directory structure creation |
| dataDir | path | ~/emulation | Root emulation directory |
| systems | list of string | (17 systems, see below) | ROM subdirectories to create |
| standaloneEmulators | list of string | ["retroarch" "ppsspp" "duckstation" "dolphin"] | Save subdirectories to create |

### Default systems

snes, nes, gb, gbc, gba, n64, nds, psx, ps2, psp, megadrive, mastersystem, gamecube, wii, dreamcast, saturn, arcade

### Default emulators (save directories)

retroarch (with saves/ and states/ subdirs), ppsspp, duckstation, dolphin

## Notes

- See `modules/system/emulation-server/` for full server setup instructions (Syncthing, Samba, WireGuard).
- Creates the directory tree under `dataDir`: `roms/<system>/`, `bios/`, and `saves/<emulator>/`.
- RetroArch gets extra subdirectories: `saves/retroarch/saves` and `saves/retroarch/states`.

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
