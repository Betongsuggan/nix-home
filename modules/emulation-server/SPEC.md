# Emulation Server

Single-file system module for hosting ROMs, BIOS files, and save data. Runs Samba (read-only ROM/BIOS shares via the `file-sharing` module) and Syncthing (bidirectional save sync). Off-LAN access is delegated to Tailscale — the module exposes its ports on the tailnet interface in addition to the configured LAN interface.

## Usage

```nix
emulation-server = {
  enable = true;
  user = "betongsuggan";
  dataDir = "/var/lib/emulation";
  # Sync with all devices registered in lib/default.nix
  syncthing.devices = inputs.self.lib.allSyncthingDevices;
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
| lanInterface | string | "enp1s0" | LAN network interface to open Syncthing/Samba ports on (ignored when `tailnetOnly = true`) |
| lanSubnet | string | "192.168.50.0/24" | LAN subnet allowed to reach Samba shares (ignored when `tailnetOnly = true`) |
| systems | list of string | 18 systems (see below) | ROM subdirectories to create |
| standaloneEmulators | list of string | ["retroarch" "ppsspp" "duckstation" "dolphin" "switch"] | Save subdirectories to create |
| tailnetOnly | bool | false | Restrict Syncthing + Samba to the tailnet — see notes below. |
| syncthing.devices | attrset of `{ id; tailnetFqdn }` | {} | Syncthing peers. Feed `inputs.self.lib.allSyncthingDevices` to pick up the entire fleet declaratively. |
| syncthing.selfSyncthingId | nullable string | null | This host's own Syncthing ID — used to filter the local entry out of the peer list. Required on hosts that include themselves in `allSyncthingDevices`. |

### Default systems

snes, nes, gb, gbc, gba, n64, nds, psx, ps2, psp, megadrive, mastersystem, gamecube, wii, dreamcast, saturn, arcade, switch

### Default emulators (save directories)

retroarch (with `saves/` and `states/` subdirs), ppsspp, duckstation, dolphin, switch

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
  roms/{snes,nes,gb,gbc,gba,n64,nds,psx,ps2,psp,megadrive,mastersystem,gamecube,wii,dreamcast,saturn,arcade,switch}/
  saves/{retroarch/{saves,states},ppsspp,duckstation,dolphin,switch}/
  bios/
    switch/            # prod.keys + title.keys (uploaded over Samba)
      firmware/        # Nintendo Switch firmware NCA files
```

### Nintendo Switch keys & firmware

Switch ROMs (`.nsp`/`.xci`/`.nsz`/`.xcz`/`.nca`/`.nro`) go in `roms/switch/`. The
BIOS-equivalent secrets — dumped from the user's own console, not distributable — live under
the BIOS share so they can be uploaded remotely over Samba and consumed by the client:

- `bios/switch/prod.keys` (and optionally `bios/switch/title.keys`)
- `bios/switch/firmware/*.nca` — the firmware as separated NCA files

On a client with the `games` module's `emulators.switch` enabled, these are symlinked into
Ryujinx's data dir automatically (`system/` for keys, `bis/system/Contents/registered/` for
firmware). See `modules/games/SPEC.md` for the client side.

### Network exposure

The module does not touch the general firewall. By default it opens Syncthing (TCP 22000, UDP 21027) and Samba (TCP 445/139, UDP 137/138) on two interfaces:

- `lanInterface` (default `enp1s0`) — LAN clients
- `tailscale0` — off-LAN clients via the tailnet

Samba additionally restricts access via `hosts allow` to the LAN subnet plus the Headscale default tailnet CIDR `100.64.0.0/10`.

### Tailnet-only mode

With `tailnetOnly = true` the network exposure collapses to the tailnet only:

- **Firewall:** Syncthing and Samba ports are opened on `tailscale0` only — the `lanInterface` opening is dropped entirely.
- **Samba `hosts allow`:** reduced to `100.64.0.0/10` only (no LAN subnet) — Samba rejects connections from any source IP outside the tailnet regardless of which interface they came in on.
- **Syncthing:** `globalAnnounceEnabled`, `relaysEnabled`, `natEnabled`, and `localAnnounceEnabled` are all set to `false`. No public-internet chatter, no LAN multicast.
- **Syncthing peer addresses:** each device gets `addresses = [ "tcp://<tailnetFqdn>:22000" ]` derived from `lib.allSyncthingDevices`. Peers without a known `tailnetFqdn` (Android devices not yet on the tailnet, fairphone's placeholder ID) fall back to `dynamic`, which won't work in tailnet-only mode — they'll be unreachable until their lib entries gain a `tailnetName`.

The trade-off: stricter posture, no public-infra footprint, every peer must be on the tailnet. Recommended once the whole personal fleet is enrolled in Headscale.

**Why `samba.interfaces` is *not* used here** even though `file-sharing` exposes the option: `bind interfaces only = yes` with `interfaces = tailscale0` makes Samba panic at boot because systemd starts smbd/nmbd before tailscaled has created the `tailscale0` interface. Firewall + `hosts allow` provide the tailnet restriction at two independent layers without that boot ordering fragility — Samba listens on all interfaces underneath, but every other layer above it rejects non-tailnet traffic. If you ever want the additional bind-only-to-tailscale0 layer, it requires a systemd ordering dependency (`samba-smbd.after = [ "tailscaled.service" ]` plus a wait-for-interface helper) that's not part of this module.

### Samba access model

The ROM and BIOS shares are configured **guest-OK, writable, delete-protected**. Concretely:

- **No password.** Any client on the LAN or tailnet can mount the shares anonymously (`guestOk = true`, `guest only = yes`). No `smbpasswd` ceremony per user. Security comes entirely from the `hosts allow` network restriction.
- **Writable.** Clients can upload new ROMs / BIOS files, overwrite existing ones, and rename. All operations run server-side as the configured `${user}` (default `betongsuggan`) via `force user`, so new files are owned consistently and existing files are modifiable.
- **Delete-protected.** Every `unlink`/`rmdir` from a client is transparently redirected into a hidden `<share-path>/.recycle/` directory by Samba's `vfs_recycle` module. Writes, updates, and overwrites still flow through normally — only intentional deletes are softened. See `modules/file-sharing/SPEC.md` for the recycle semantics in full.

Clients access shares at `smb://<host>/emulation-roms` (LAN/tailnet) with no authentication. On Linux: `mount -t cifs //<host>/emulation-roms /mnt -o guest`. On Android: pick "Anonymous" or leave username/password blank.

**Operator hygiene:** periodically check the recycle dirs:

```bash
sudo du -sh /var/lib/emulation/roms/.recycle /var/lib/emulation/bios/.recycle
sudo ls /var/lib/emulation/roms/.recycle    # inspect before purging
sudo rm -rf /var/lib/emulation/roms/.recycle/*   # when ready
```

### Syncthing device setup

Each client's device ID is visible in its Syncthing web UI at `http://localhost:8384` (Actions > Show ID). Add it to `syncthing.devices`, rebuild, then accept the `emulation-saves` folder share on the client side.

### Verification

```bash
systemctl status syncthing                   # Syncthing (web UI at http://localhost:8384)
smbclient -L localhost -N                    # -N = no password (guest); should list emulation-roms + emulation-bios
sudo ss -tlnp | grep -E ':(22000|445|139)'   # confirm listeners
```

From a remote client on the LAN or tailnet, the same listing test:

```bash
smbclient -L controller -N
```

### Android client setup

Android devices don't run NixOS modules but can still join the save-sync mesh.

#### Save sync via Syncthing

1. Install **Syncthing** from F-Droid or Play Store.
2. Open Syncthing and note your device ID.
3. Add the device to `lib/default.nix` under `devices`:
   ```nix
   devices.my-phone = {
     type = "android";
     description = "My Android phone";
     syncthing.id = "YOUR-DEVICE-ID-HERE";
   };
   ```
4. Rebuild the server (the device is picked up automatically via `allSyncthingDevices`).
5. On Android, add the server as a device using the server's device ID (find it at `http://server:8384` > Actions > Show ID).
6. Accept the `emulation-saves` folder share. Point it at `/storage/emulated/0/emulation/saves`.

#### ROM access via Samba

Most Android file managers (Material Files, X-plore, Solid Explorer, CX File Explorer, etc.) support SMB. Connect to `<server>/emulation-roms` or `<server>/emulation-bios` and select "Anonymous" / "Guest" — no username or password.

#### Off-LAN access

Install the **Tailscale** app, sign in against the Headscale coordinator, and use the server's tailnet hostname / IP. No separate tunnel needed.
