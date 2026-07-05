# Games

Provides a full Linux gaming setup including Steam, Lutris, MangoHud performance overlay, vkBasalt post-processing, Proton-GE compatibility, emulators (RetroArch + standalone), Steam library integration (BoilR + Steam ROM Manager), and various gaming utilities.

## Usage

```nix
games = {
  enable = true;
  mangohud = {
    enable = true;
    detailedMode = true;
    position = "top-left";
    fontSize = 24;
  };
  vkbasalt.enable = true;
  protonGE.enable = true;
  tools.enable = true;
  emulators = {
    enable = true;
    # dataDir = "emulation";  # default, relative to $HOME
    # retroarch.enable = true;  # default
    # retroarch.cores = [ "snes9x" "fceumm" ... ];  # all 10 cores by default
    # standalone.pcsx2 = true;  # default
    # standalone.dolphin = true;  # default
    # standalone.ppsspp = true;  # default
    switch = {
      enable = true;            # off by default
      # emulator = "ryubing";   # default; also "citron" or "eden" (all from unstable)
    };
  };
  steamIntegration = {
    enable = true;
    # boilr = true;  # default
    # steamRomManager = true;  # default
  };
};
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Enable gaming setup |
| mangohud.enable | bool | true | Enable MangoHud overlay |
| mangohud.detailedMode | bool | true | Show detailed system information in MangoHud (CPU per-core load, swap, memory, network, IO, etc.) |
| mangohud.controllerToggle | bool | false | Enable controller-based MangoHud toggle (deprecated -- use controller module instead) |
| mangohud.position | enum | "top-left" | MangoHud overlay position. One of: "top-left", "top-right", "bottom-left", "bottom-right", "top-center", "bottom-center" |
| mangohud.fontSize | int | 24 | MangoHud font size |
| vkbasalt.enable | bool | false | Enable vkBasalt post-processing |
| protonGE.enable | bool | false | Enable Proton-GE (installs to Steam compatibility tools directory) |
| tools.enable | bool | true | Install gaming tools (goverlay, protonup-qt, winetricks, protontricks, bottles, heroic) |
| emulators.enable | bool | false | Enable emulators (RetroArch + standalone) |
| emulators.dataDir | str | "emulation" | Directory name under $HOME for emulation data (ROMs, saves, BIOS) |
| emulators.retroarch.enable | bool | true | Enable RetroArch with libretro cores |
| emulators.retroarch.cores | list of str | (all 10 cores) | List of libretro core names to include |
| emulators.standalone.pcsx2 | bool | true | Install PCSX2 (PS2 emulator) |
| emulators.standalone.dolphin | bool | true | Install Dolphin (GameCube/Wii emulator) |
| emulators.standalone.ppsspp | bool | true | Install PPSSPP (PSP emulator) |
| emulators.switch.enable | bool | false | Enable Nintendo Switch emulation |
| emulators.switch.emulator | enum | "ryubing" | Switch fork to install from unstable: "ryubing" (Ryujinx fork, recommended), "citron", or "eden" |
| emulators.switch.dataDir | str | `${home}/${emulators.dataDir}/saves/switch` | Ryujinx `--root-data-dir` (keys, firmware, saves). Only used when emulator = "ryubing" |
| emulators.switch.quitChord.enable | bool | true | Hold Select+Start on the streamed gamepad to quit the running Switch game |
| emulators.switch.quitChord.holdSeconds | float | 1.5 | How long Select+Start must be held before the game closes |
| steamIntegration.enable | bool | false | Enable Steam library integration |
| steamIntegration.boilr | bool | true | Install BoilR to import games from Heroic/Lutris/etc. into Steam |
| steamIntegration.steamRomManager | bool | true | Install Steam ROM Manager to create per-ROM Steam shortcuts with artwork |

## RetroArch Core-to-System Mapping

| Core | Systems | Package |
|------|---------|---------|
| snes9x | SNES | `libretro.snes9x` |
| fceumm | NES | `libretro.fceumm` |
| mgba | GB, GBC, GBA | `libretro.mgba` |
| mupen64plus | N64 | `libretro.mupen64plus` |
| melonds | NDS | `libretro.melonds` |
| beetle-psx-hw | PSX | `libretro.beetle-psx-hw` |
| genesis-plus-gx | Mega Drive, Master System | `libretro.genesis-plus-gx` |
| flycast | Dreamcast | `libretro.flycast` |
| beetle-saturn | Saturn | `libretro.beetle-saturn` |
| fbneo | Arcade | `libretro.fbneo` |

## First-Time Setup

### RetroArch
- BIOS files must be manually placed in `~/emulation/bios/` (or your configured dataDir)
- ROMs go in `~/emulation/roms/` organized by system subdirectory
- RetroArch is configured declaratively via Nix wrapper `settings` (paths, Vulkan, udev joypad, Ozone menu)
- Runtime config changes are preserved since `config_save_on_exit` is enabled

### BoilR
- Run `boilr` once to scan and import games from Heroic, Lutris, and other launchers into Steam
- Re-run when adding new games to external launchers
- Automatically fetches artwork from SteamGridDB

### Steam ROM Manager
- Configure parsers per system pointing at `~/emulation/roms/{system}/`
- Run to generate individual Steam shortcuts with artwork for each ROM
- Each ROM appears as its own entry in Steam Big Picture

### Nintendo Switch (headless / remote setup)

Designed to be set up entirely over SSH + Moonlight, with no local GUI. yuzu and the
original Ryujinx were taken down by Nintendo in 2024; the default emulator is **Ryubing**
(the maintained Ryujinx fork), pulled from `unstable`. Its `Ryujinx` binary boots straight
into a game, which is what the per-game Steam-shortcut model needs.

Steam shortcuts are written **directly into `shortcuts.vdf`** by a small Python + `vdf`
script (`switch-add-shortcuts.py`), invoked by `switch-apply-shortcuts`. Steam ROM Manager is
*not* used for Switch: its Electron CLI hangs headless on this host (never returns after
"Fetching parsers…", under both Xvfb and an attached Wayland session). The direct writer
needs no display/GPU/D-Bus and is idempotent (upserts by app name).

**Prerequisites**
- The user must have this host's `emulation-mounts` (system module) access so
  `~/emulation/{roms,bios}` mount from the controller (BIOS share holds keys/firmware).
- Steam must have been logged into at least once so a Steam user data dir exists
  (`userdata/<id>/config/shortcuts.vdf`).

**Data flow** — you upload keys/firmware/ROMs to the controller's Samba shares; the desktop
reads them over the auto-mounted shares:

| Item | Uploaded to (controller, over Samba) | Consumed on the desktop |
|------|--------------------------------------|-------------------------|
| `prod.keys` / `title.keys` | `bios/switch/` | **copied** into `<dataDir>/system/` by `switch-refresh-keys` (real local files, not symlinks) |
| firmware | (from a game cartridge, or a dump) | **installed once** via the Ryujinx UI → stored in `<dataDir>/bis/…` (persists + syncs) |
| ROMs | `roms/switch/<Game>/…` — one folder per game holding the base `.xci` (plus optional `(UPD).nsp`) | read live from `~/emulation/roms/switch` |

The shortcut writer picks the base `.xci` per game folder (ignoring `(UPD)`/`(DLC)` files), so
each folder becomes one Steam shortcut named after the folder. It writes a small launcher
script (`~/.local/share/switch-shortcuts/<game>.sh`) that runs
`Ryujinx --root-data-dir <dataDir> "<base.xci>"`, and points the Steam shortcut's `exe` at it
(empty LaunchOptions) — this sidesteps Steam mangling the quoting of space-filled paths.
Updates/DLC are applied separately via Ryujinx's title manager.

**Things this depends on (all handled in the modules):**
- **ROM share must be mounted `cache=none`** (`modules/emulation-client/system.nix`). The
  default `cache=strict` corrupts random-access reads deep into multi-GB `.xci` files over the
  tailnet CIFS link → `LibHac ResultFsOutOfRange` / "no valid application". If gameplay
  stutters from uncached reads, try `cache=loose`.
- **Ryujinx must open fullscreen on the SUNSHINE monitor** — a Hyprland window rule
  (`fullscreen, class:^(Ryujinx)$` in `hosts/desktop/user-gamer.nix`); without it the game
  renders *behind* Big Picture's fullscreen window (audio but no video on the stream).
- **Controller plumbing** (see "Sunshine virtual pad → Ryujinx" below): a source patch on
  ryubing, an SDL controller-DB entry in the data dir, and two SDL env vars set by
  `switch-run-emulator`. All declarative; plus one manual Steam setting (Steam Input off).

**Sunshine virtual pad → Ryujinx (controller pipeline)**

The Moonlight-forwarded gamepad reaches the host as a uinput device
("Sunshine X-Box One (virtual) pad", `045e:02ea`). Four independent layers each broke it
and each has a fix in this module:

| Layer | Problem | Fix |
|-------|---------|-----|
| Steam Input | Steam holds an exclusive `EVIOCGRAB` on the pad's evdev node, so Ryujinx receives no events | **Manual, once:** Big Picture → Settings → Controller → disable Steam Input for Xbox controllers (or per-tile Force Off). Steam merely *observing* the node is fine — only the grab hurts. |
| SDL udev enumeration | The udev path misses the hotplugged pad | `SDL_JOYSTICK_DISABLE_UDEV=1` (set by `switch-run-emulator`) forces the direct `/dev/input` scan, which sees it |
| SDL gamecontroller DB | The pad's GUID embeds a CRC of its device name + a nonstandard version, so SDL's built-in DB never matches → "joystick but not gamecontroller" → invisible to Ryujinx | `switch-refresh-input` installs `<dataDir>/SDL_GameControllerDB.txt` (standard xpad layout), which Ryujinx loads natively at startup |
| ryubing device-index bug | Ryujinx opens controllers by position in its own filtered list, but `SDL_GameControllerOpen` wants SDL's device index (which also counts non-gamepad joysticks like the G13 thumbstick and Sunshine's pen/touch passthrough) → opens the wrong device → NULL → dropped from the Input list | `ryubing-sdl2-device-index.patch` (applied via `overrideAttrs`) resolves the index through the joystick instance id |
| Player binding | Ryujinx needs a Player 1 `input_config` entry whose `id` matches the pad (`0-<guid>` with the name-CRC nibbles zeroed) — hand-guessed ids never match | `switch-apply-input` merges a known-good, in-game-verified binding into `<dataDir>/Config.json`, keyed by the pad GUID; idempotent and leaves all other settings untouched |

`switch-run-emulator` is the canonical entrypoint (generated Steam launchers use it; use it
manually too, e.g. for the one-time binding: `switch-run-emulator` with no ROM opens the GUI
with the menu bar visible). `SDL_JOYSTICK_HIDAPI=0` is also set — the virtual pad has no
hidraw node, so HIDAPI must not claim it.

**Quitting a game without a keyboard (`quitChord`)**

Over Moonlight there is no keyboard, and the Steam overlay's "close game" is unavailable
(Steam Input must stay off for the pad to reach Ryujinx). The `switch-quit-listener`
systemd user service (same shape as `controller-mangohud-toggle`) watches the Sunshine
virtual pad's evdev node — hotplug-aware, since Sunshine creates the pad lazily on first
input — and when **Select+Start are held together** for `quitChord.holdSeconds`, it closes
the Ryujinx window via `hyprctl dispatch closewindow class:Ryujinx` (the clean-shutdown
path, identical to clicking ✕), falling back to SIGTERM if the window ignores it for 5 s.
Big Picture is still fullscreen underneath, so the stream lands back on the game library.
Note: the chord cannot save the game first — save in-game, then quit.

**Steps (all remote)**
1. Rebuild the host with `emulators.switch.enable = true`. On activation, `switch-refresh-keys`
   copies the keys into the data dir.
2. From any machine, mount `//controller/emulation-bios` (guest) and drop `prod.keys`
   (+ `title.keys`) in `switch/`; put ROMs on `//controller/emulation-roms` under
   `switch/<Game>/` (base `.xci` per folder).
3. Generate the Steam tiles: run `switch-apply-shortcuts` over SSH — it stops Steam, copies
   keys, and writes `shortcuts.vdf`. Reconnect the Moonlight "Steam Gaming" app to see them.
4. **One-time in Steam:** disable Steam Input so Steam releases its exclusive grab on the
   pad: Big Picture → Settings → Controller → turn off Steam Input for Xbox controllers
   (or per-tile: game tile → gear → Controller → Force Off).
5. **One-time per data dir:** launch a game; when Ryujinx prompts, install firmware (from the
   cartridge, or Tools → Install Firmware). It persists in `<dataDir>` (synced).
   The controller binding needs **no manual step**: `switch-apply-input` (run at activation
   and by `switch-apply-shortcuts`) merges the verified Player 1 binding into
   `<dataDir>/Config.json`. Note the merge is a no-op until Ryujinx has run once and created
   `Config.json` — after the very first game launch, run `switch-apply-input` (or re-run
   `switch-apply-shortcuts`) once.

**Notes / caveats**
- Shortcuts carry no artwork (SteamGridDB matching was SRM's job); tiles show a default icon.
  Artwork can be added later by dropping images into `userdata/<id>/config/grid/`.
- Ryujinx's `"start_fullscreen": true` (in `<dataDir>/Config.json`) hides its menu bar so only
  the game shows; F11 toggles it at runtime.
- `citron`/`eden` don't use Ryujinx's `--root-data-dir`; the key-copy and `dataDir` apply only
  to `ryubing`. For those forks, place keys/firmware in their own data dirs manually.

### Battle.net
- Install via Bottles (already available via `tools.enable`)
- Manually add game shortcuts to Steam after installation

## Notes

- MangoHud is hidden by default and can be toggled with Shift_R+F9.
- MangoHud is enabled session-wide when active.
- Base packages always installed: chiaki, discord, evtest, gamemode, lutris, steam, steam-run, sc-controller, vulkan-tools, mesa-demos.
- RetroArch uses the `retroarch-bare.wrapper` function for declarative configuration while preserving runtime changes.
- Standalone emulators (PCSX2, Dolphin, PPSSPP) are for systems that benefit from dedicated emulators over RetroArch cores. (Duckstation was removed from nixpkgs 26.05 upstream; PSX is covered by RetroArch's beetle-psx-hw core.)
- Switch emulation (`emulators.switch`) is pulled from `unstable` (ryubing carries a local source patch, `ryubing-sdl2-device-index.patch`, so it rebuilds from source). It ships five helper scripts: `switch-refresh-keys` (copy keys from the BIOS share into the data dir), `switch-refresh-input` (install the Sunshine-pad SDL controller DB into the data dir), `switch-apply-input` (merge the verified Player 1 pad binding into `Config.json`, GUID-keyed and idempotent), `switch-run-emulator` (canonical launch wrapper setting the SDL env vars), and `switch-apply-shortcuts` (stop Steam, refresh keys+input+binding, write `shortcuts.vdf` directly via a Python+`vdf` script — SRM's headless CLI hangs on this host, so it's bypassed for Switch).
