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
    # standalone.duckstation = true;  # default
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
| emulators.standalone.duckstation | bool | true | Install Duckstation (PSX emulator) |
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

### Battle.net
- Install via Bottles (already available via `tools.enable`)
- Manually add game shortcuts to Steam after installation

## Notes

- MangoHud is hidden by default and can be toggled with Shift_R+F9.
- MangoHud is enabled session-wide when active.
- Base packages always installed: chiaki, discord, evtest, gamemode, lutris, steam, steam-run, sc-controller, vulkan-tools, mesa-demos.
- RetroArch uses the `retroarch-bare.wrapper` function for declarative configuration while preserving runtime changes.
- Standalone emulators (PCSX2, Dolphin, PPSSPP, Duckstation) are for systems that benefit from dedicated emulators over RetroArch cores.
