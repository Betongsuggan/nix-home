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

**Prerequisites**
- The user must have this host's `emulation-mounts` (system module) access so
  `~/emulation/{roms,bios}` mount from the controller (BIOS share holds keys/firmware).
- Steam must have been logged into at least once so a Steam user data dir exists (SRM writes
  its `shortcuts.vdf`).

**Data flow** — keys/firmware are uploaded to the controller's BIOS Samba share and
symlinked into Ryujinx's data dir automatically at `home-manager switch`:

| Item | Uploaded to (controller, over Samba) | Symlinked into (Ryujinx `dataDir`) |
|------|--------------------------------------|-------------------------------------|
| `prod.keys` / `title.keys` | `bios/switch/` | `system/` |
| firmware `*.nca` | `bios/switch/firmware/` | `bis/system/Contents/registered/` |
| ROMs (`.nsp/.xci/.nsz/.xcz/.nca/.nro`) | `roms/switch/` | (read directly from `~/emulation/roms/switch`) |

**Steps (all remote)**
1. Rebuild the host with `emulators.switch.enable = true`. On activation, keys/firmware get
   linked and a **Nintendo Switch** parser is upserted into SRM's `userConfigurations.json`
   (writable, so any GUI-made parsers are preserved).
2. From any machine, mount `//controller/emulation-bios` (guest) and drop `prod.keys`
   (+ firmware `.nca`s under `switch/firmware/`); put ROMs on `//controller/emulation-roms`
   under `switch/`.
3. Refresh firmware links without a full rebuild: run `switch-refresh-firmware` over SSH.
4. Generate the Steam tiles headlessly: run `switch-apply-shortcuts` over SSH — it stops
   Steam, relinks firmware, and runs `steam-rom-manager add` under a virtual X display
   (`xvfb-run`), then reconnect the Moonlight "Steam Gaming" app to see them.

**Notes / caveats**
- Validate the generated parser on-target with `steam-rom-manager list`. SRM's
  `userConfigurations.json` schema is version-locked; the module writes on-disk schema
  `version: 10` and SRM migrates older versions on load — adjust if the installed build
  rejects it.
- **Firmware fallback:** if Ryujinx doesn't detect the symlinked firmware (the `registered/`
  layout can be version-sensitive), do a one-time `Tools → Install Firmware → from directory`
  pointed at `~/emulation/bios/switch/firmware` over the Moonlight stream. Everything else
  stays headless.
- `citron`/`eden` don't use Ryujinx's `--root-data-dir`; the keys/firmware auto-symlink and
  `dataDir` apply only to `ryubing`. For those forks, place keys/firmware in their own data
  dirs manually.

### Battle.net
- Install via Bottles (already available via `tools.enable`)
- Manually add game shortcuts to Steam after installation

## Notes

- MangoHud is hidden by default and can be toggled with Shift_R+F9.
- MangoHud is enabled session-wide when active.
- Base packages always installed: chiaki, discord, evtest, gamemode, lutris, steam, steam-run, sc-controller, vulkan-tools, mesa-demos.
- RetroArch uses the `retroarch-bare.wrapper` function for declarative configuration while preserving runtime changes.
- Standalone emulators (PCSX2, Dolphin, PPSSPP) are for systems that benefit from dedicated emulators over RetroArch cores. (Duckstation was removed from nixpkgs 26.05 upstream; PSX is covered by RetroArch's beetle-psx-hw core.)
- Switch emulation (`emulators.switch`) is pulled from `unstable`. It ships two helper scripts: `switch-refresh-firmware` (relink keys/firmware from the BIOS share) and `switch-apply-shortcuts` (headless `steam-rom-manager add`). The SRM parser is managed declaratively via an idempotent activation upsert into `userConfigurations.json`.
