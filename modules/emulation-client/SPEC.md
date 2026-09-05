# Emulation Client

User-level module for NixOS machines that connect to the emulation server. Enables Syncthing for save file synchronization and provides a helper script for mounting ROM/BIOS Samba shares.

## Usage

```nix
emulation-client = {
  enable = true;
  # Use the tailnet FQDN: controller runs `emulation-server.tailnetOnly = true`,
  # so Samba/Syncthing are NOT reachable via its LAN IP.
  server.address = inputs.self.lib.tailnet.fqdn "controller";
};
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Enable emulation client (save sync + ROM access) |
| savesDir | path | ~/emulation/saves | Local directory for synced save files |
| server.address | string | "desktop" | Address of the emulation server (hostname or IP) |
| standaloneEmulators | list of string | ["retroarch" "ppsspp" "dolphin" "switch"] | Standalone emulators to create save subdirectories for |

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

### Connecting Syncthing (declarative — no manual pairing)

The module declares controller as a known peer with a pinned tailnet address and pre-configures the `emulation-saves` folder pointing at `cfg.savesDir`. On rebuild the daemon comes up already paired — there is no web-UI clicking step on the Linux side.

The other half of the handshake is on the server: controller's `emulation-server` reads `inputs.self.lib.allSyncthingDevices`, which collects every Syncthing ID declared under `lib/default.nix` (host-level via `hosts.<h>.syncthing.id`, per-user via `hosts.<h>.users.<u>.syncthing.id`, or non-NixOS via `devices.<d>.syncthing.id`). To onboard a new Linux client, add its Syncthing ID to lib in the appropriate slot and rebuild controller; the matching declaration in this module's config picks up controller's side automatically.

Saves sync bidirectionally — `type = "sendreceive"`. Changes made offline sync automatically when devices reconnect.

The local Syncthing web UI at `http://localhost:8384` is still useful for observability (sync status, recent activity), but it's not part of the pairing flow.

### Mounting ROM and BIOS shares

There are two ways: declarative automount (recommended) or the manual helper script.

**Automount via the `emulation-mounts` system module** (see `modules/emulation-client/system.nix`). Enable it in the host's `system.nix` listing each user that should get the shares under their home:

```nix
emulation-mounts = {
  enable = true;
  server = inputs.self.lib.tailnet.fqdn "controller";
  users = [ "betongsuggan" "gamer" ];
};
```

This generates `x-systemd.automount` mounts at `/home/<user>/emulation/{roms,bios}`. They don't actually mount until the path is first accessed, so there's no boot delay and no failure if controller is offline (the dir is just empty). After 60s of inactivity the mount is dropped automatically.

The mounts use `closetimeo=0` to disable CIFS deferred-close handle caching. Without it, a shutdown that happens while a ROM was recently open (e.g. a Switch `.xci` in Ryujinx) *and* the server has become unreachable can leave a busy inode that trips `kernel BUG at fs/super.c:654` ("Busy inodes after unmount of cifs") — hanging shutdown in PID 1 and forcing a hard power-off. Closing handles immediately removes that trigger.

`closetimeo=0` only covers *recently closed* handles, though. If a process still has a ROM **open** when shutdown starts (e.g. a game left running) and tailscaled stops before the unmount, the process gets stuck in an uninterruptible CIFS wait against the now-unreachable server, the handle is never released, and the same `fs/super.c:654` kernel BUG fires (this happened 2026-07-01; the host needed a manual power-cycle). To close that gap, when the host has `services.tailscale.enable` the mounts also carry `x-systemd.requires=tailscaled.service`, ordering mount-after and unmount-*before* tailscaled — so the server stays reachable while sessions are torn down and the shares unmount. Safest reboot procedure remains: quit the running game first.

**Manual helper script** (still installed by the user-side module — useful for ad-hoc mounts to alternate locations or debugging):

```bash
mount-emulation-roms                # default: configured server.address
mount-emulation-roms controller     # override server
```

Either way, the mount uses anonymous (guest) auth — no password prompt. Shares are **writable** (you can drop new ROMs / BIOS files in) but with server-side delete protection: any deletes through the mount are transparently moved to a hidden `.recycle/` directory on the server rather than actually unlinked. See `modules/emulation-server/SPEC.md` for the operator-side recycle hygiene.

To unmount a manually-mounted share:

```bash
sudo umount ~/emulation/roms ~/emulation/bios
```

### Off-LAN access

The server exposes Syncthing and Samba on its `tailscale0` interface as well as the LAN. To use the server while away from home, enable the `tailscale-client` module on this host and pass the server's tailnet hostname as `server.address` (or run `mount-emulation-roms <tailnet-hostname>` ad-hoc).

### Pointing emulators at the save directory

Configure each emulator to use `~/emulation/saves/<emulator>/` for saves:

- **RetroArch**: declarative — the `games` module's wrapper settings pin
  Savefile = `~/emulation/saves/retroarch/saves` and Savestate =
  `~/emulation/saves/retroarch/states` (see `modules/games/default.nix`); no
  manual step
- **Switch (Ryubing)**: declarative — `games.emulators.switch.dataDir` defaults
  to `~/emulation/saves/switch`
- **PPSSPP**: Settings > System > Save path = `~/emulation/saves/ppsspp`
- **Dolphin**: Config > Paths > Wii NAND Root / GC Memory Cards = `~/emulation/saves/dolphin`

### Onboarding a new client user

Syncthing pairing is declarative on both ends, but the server must know the
client's device ID: run `syncthing --device-id` as the client user (the ID is
generated on first daemon start), add it in `lib/default.nix` under
`hosts.<host>.users.<user>.syncthing.id`, and rebuild controller. Note this is
**per user** — e.g. `gamer@desktop` has its own ID, separate from
`betongsuggan@desktop`.
