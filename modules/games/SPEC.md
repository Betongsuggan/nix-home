# Games

Provides a full Linux gaming setup including Steam, Lutris, MangoHud performance overlay, vkBasalt post-processing, Proton-GE compatibility, emulators (RetroArch + standalone), per-ROM Steam tiles written directly into `shortcuts.vdf` (`emulators.steamShortcuts`), Steam library integration for store launchers (BoilR), and various gaming utilities.

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
    steamShortcuts = {
      enable = true;            # off by default — per-ROM Steam tiles
      artwork.apiKeyFile = "/run/secrets/steamgriddb-api-key";
      # systems.<name>.{enable,romDir,extensions,layout,command,windowClass,tag,launcherDir}
      # are generated per enabled RetroArch core (+ switch) and overridable piecemeal:
      # systems.n64.enable = false;
    };
    switch = {
      enable = true;            # off by default
      # emulator = "ryubing";   # default; also "citron" or "eden" (all from unstable)
    };
  };
  steamIntegration = {
    enable = true;
    # boilr = true;  # default
    # steamRomManager = true;  # default (installed, but unused for ROM tiles — see below)
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
| emulators.steamShortcuts.enable | bool | false | Per-ROM Steam tiles written directly into `shortcuts.vdf` by `emulation-apply-shortcuts` |
| emulators.steamShortcuts.artwork.apiKeyFile | nullOr str | null | Path to a file with a SteamGridDB API key (e.g. a sops `/run/secrets` path, read at runtime). When set, `emulation-apply-shortcuts` fetches Steam grid artwork per game. (Moved here from `emulators.switch.artwork.apiKeyFile`.) |
| emulators.steamShortcuts.systems | attrsOf submodule | generated | Systems to generate tiles for; defaults generated per enabled RetroArch core (+ Switch), merged with host overrides. Fields: `enable`, `romDir`, `extensions`, `layout` ("flat"\|"folder"), `command` (argv prefix, ROM appended), `windowClass`, `tag`, `launcherDir` |
| steamIntegration.enable | bool | false | Enable Steam library integration |
| steamIntegration.boilr | bool | true | Install BoilR to import games from Heroic/Lutris/etc. into Steam |
| steamIntegration.steamRomManager | bool | true | Install Steam ROM Manager (unused for ROM tiles — its headless CLI hangs on this host; `emulation-apply-shortcuts` replaces it) |

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

## Steam tiles for emulated systems (`emulators.steamShortcuts`)

Every ROM becomes its own Steam Big Picture tile with SteamGridDB artwork, written
**directly into `shortcuts.vdf`** by `emulation-apply-shortcuts`. Steam ROM Manager is
*not* used: its Electron CLI hangs headless on this host (never returns after
"Fetching parsers…", under both Xvfb and an attached Wayland session). The direct writer
needs no display/GPU/D-Bus and is idempotent.

**Architecture:** Nix builds a JSON manifest (per system: ROM dir, extensions, layout,
launch argv, Hyprland window class, Steam tag, launcher dir) from
`emulators.steamShortcuts.systems`; `add-shortcuts.py` consumes it in one run.
Default entries are generated for every enabled RetroArch core with a known mapping,
plus Switch when `emulators.switch.enable` — all fields `mkDefault`'d, so hosts
override piecemeal (`systems.n64.enable = false;`, `systems.snes.tag = "…";`) or add
custom systems (e.g. a standalone emulator) as one new entry.

**Default systems** (gated on the corresponding core being in `retroarch.cores`):

| System | Core | Extensions | Tag |
|--------|------|------------|-----|
| snes | snes9x | .sfc .smc .zip | SNES |
| nes | fceumm | .nes .zip | NES |
| gb / gbc / gba | mgba | .gb / .gbc / .gba (+.zip) | Game Boy (Color/Advance) |
| n64 | mupen64plus | .n64 .z64 .v64 .zip | Nintendo 64 |
| psx | beetle-psx-hw | .m3u .cue .chd .pbp | PlayStation |
| megadrive | genesis-plus-gx | .md .gen .bin .zip | Mega Drive |
| mastersystem | genesis-plus-gx | .sms .zip | Master System |
| switch (when enabled) | Ryubing | .xci (folder layout) | Nintendo Switch |

Deferred on purpose: nds/dreamcast/saturn/arcade cores need writable or subdirectory
BIOS layouts the read-only flat BIOS mount doesn't provide; standalone emulators
(PS2/GC/PSP) each need controller/save-path validation. Each becomes a one-entry
`systems` addition once solved.

**Semantics** (see `add-shortcuts.py`):
- **Layouts:** `flat` = one tile per ROM file (name = filename stem); `folder` = one
  tile per subdirectory launching the base file, skipping `(UPD)`/`(DLC)` (Switch).
  Flat dedups multi-file games: files whose stem extends an `.m3u` playlist's stem are
  skipped, and same-stem siblings resolve `.m3u` > `.cue` > `.chd` — a multi-disc PSX
  game is one tile.
- **Launchers:** per-game scripts under `launcherDir` (default
  `~/.local/share/emulation-shortcuts/<system>/`; Switch keeps its legacy
  `~/.local/share/switch-shortcuts/`) that poll `hyprctl` for the emulator's window
  class and fullscreen it over Big Picture, then exec the manifest command with the
  ROM appended — Steam never parses the paths.
- **Upsert keyed by exe path** (not app name — the same title can exist on two
  systems); the per-system `tag` becomes a Steam collection. `LastPlayTime` is
  preserved across re-runs.
- **Pruning:** entries whose launcher lives under a managed `launcherDir` but wasn't
  produced this run are removed (ROM deleted/renamed), along with the orphaned
  launcher script. Systems that yield zero games are skipped entirely — an
  unreachable/empty CIFS automount never wipes tiles. BoilR/manual shortcuts are
  never touched.
- **Appid stability:** the appid hashes launcher path + name, so artwork,
  collections, and playtime survive re-runs; changing `launcherDir` or renaming a
  ROM orphans them.
- **Artwork:** same SteamGridDB flow as before (see the Switch artwork section);
  `.sgdbid` overrides live in the game folder (folder layout) or as
  `<RomStem>.sgdbid` next to the ROM (flat layout). Re-fetch with
  `EMU_ARTWORK_FORCE=1 emulation-apply-shortcuts`.

`switch-apply-shortcuts` remains as a deprecated alias that execs
`emulation-apply-shortcuts`.

## First-Time Setup

### RetroArch
- BIOS files go **flat** in `~/emulation/bios/` (the read-only CIFS mount of the
  controller's `emulation-bios` share) — e.g. `scph5500.bin`/`scph5501.bin`/
  `scph5502.bin` for PSX (beetle-psx-hw fails to boot discs silently without them),
  optionally `gba_bios.bin` for mGBA. Upload them to the share; see
  `modules/emulation-server/SPEC.md`.
- ROMs go in `~/emulation/roms/` organized by system subdirectory
- RetroArch is configured declaratively via Nix wrapper `settings`: paths (saves and
  states inside the Syncthing-synced `~/emulation/saves/retroarch/{saves,states}`),
  Vulkan, udev joypad, Ozone menu
- Runtime config changes to *undeclared* keys are preserved (`config_save_on_exit`);
  declared keys re-win on every launch via `--appendconfig`
- **Streamed gamepad:** a udev autoconfig profile for the Sunshine virtual pad is
  baked in (merged with the upstream autoconfig DB via `symlinkJoin`, so physical
  pads keep working). Hotkeys mirror the Switch quit chord: **hold Select + press
  Start = quit** (clean exit, SRAM flushed to the synced saves dir), **Select +
  Guide = RetroArch menu**. RetroPad convention note: `input_b` is the *bottom*
  face button — if confirm/cancel feel swapped in-game, the autoconfig's b/a and
  y/x assignments in `modules/games/default.nix` are the place to flip.

### Cross-device save sync (Android handheld / Ayn Thor)

The Ayn Odin 2 ("Thor") plays the same games natively (Cocoon frontend → RetroArch
Android) and shares the `emulation-saves` Syncthing folder through controller
(hub-and-spoke: Thor ↔ controller ↔ desktop-gamer). Saves continue across devices
when both sides honor the same **layout contract**, which this module pins
declaratively on the desktop:

- **Flat layout**: saves in `<saves>/retroarch/saves`, states in
  `<saves>/retroarch/states`, all four `sort_save*` options and both
  `*_in_content_dir` options **off** — a mismatch means each device reads/writes
  different paths and nothing "syncs".
- **Filename parity**: RetroArch names `.srm` after the ROM's basename, so the
  Thor's local ROM copies must keep the exact filenames from the `emulation-roms`
  share.
- **SaveRAM autosave every 60s** (`autosave_interval`): saves survive crashes and
  sync without waiting for a clean quit. Mirror the setting on the Thor.

Expectations:

- **In-game saves (`.srm`) are portable** across platforms — this is the
  continue-anywhere mechanism.
- **Savestates are core-version-sensitive**: they sync but may not load on the
  other device's core build. Save in-game for cross-device handoff; treat states
  as per-device conveniences.
- **One device at a time per game**: simultaneous play produces Syncthing
  `.sync-conflict-*` files (versioning keeps 5 — recoverable, but avoid it).
- **Switch is not portable**: desktop Ryujinx and Android Switch emulators have
  incompatible save layouts. Switch continuity across devices = stream the
  desktop session via Moonlight.
- **Cocoon is config-neutral**: it only launches RetroArch; all save behavior
  lives in RetroArch's own settings.

The Thor-side (manual) setup steps live in `modules/emulation-server/SPEC.md`
under "Android client setup".

### BoilR
- Run `boilr` once to scan and import games from Heroic, Lutris, and other launchers into Steam
- Re-run when adding new games to external launchers
- Automatically fetches artwork from SteamGridDB

### Nintendo Switch (headless / remote setup)

Designed to be set up entirely over SSH + Moonlight, with no local GUI. yuzu and the
original Ryujinx were taken down by Nintendo in 2024; the default emulator is **Ryubing**
(the maintained Ryujinx fork), pulled from `unstable`. Its `Ryujinx` binary boots straight
into a game, which is what the per-game Steam-shortcut model needs.

Steam shortcuts are written **directly into `shortcuts.vdf`** by `add-shortcuts.py`,
invoked by `emulation-apply-shortcuts` (Switch is one `steamShortcuts.systems` entry —
folder layout, `.xci`; see "Steam tiles for emulated systems" above). The old
`switch-apply-shortcuts` name survives as a deprecated alias.

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
script (`~/.local/share/switch-shortcuts/<game>.sh` — the legacy dir is kept so existing
tiles' appids, artwork, and collections survive) that runs
`Ryujinx --root-data-dir <dataDir> "<base.xci>"`, and points the Steam shortcut's `exe` at it
(empty LaunchOptions) — this sidesteps Steam mangling the quoting of space-filled paths.
Updates/DLC are applied separately via Ryujinx's title manager.

**Things this depends on (all handled in the modules):**
- **ROM share must be mounted `cache=none`** (`modules/emulation-client/system.nix`). The
  default `cache=strict` corrupts random-access reads deep into multi-GB `.xci` files over the
  tailnet CIFS link → `LibHac ResultFsOutOfRange` / "no valid application". If gameplay
  stutters from uncached reads, try `cache=loose`.
- **Ryujinx must open fullscreen on the SUNSHINE monitor** — the generated per-game
  launcher polls `hyprctl` for the emulator's window class and fullscreens it at runtime
  (Hyprland 0.55 dropped the old `fullscreen` window-rule form); without it the game
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

The baked binding uses a **direct 1:1 (Nintendo-label) face-button map** — the pad's
A/B/X/Y drive the Switch A/B/X/Y of the same name, so printed letters match in-game
actions. (ryubing's default position-swaps A/B and X/Y, which lands actions on the
wrong buttons, e.g. jump on Y instead of X.) If a pad ever comes out mirrored, flip
the relevant `button_*` values in `switchInputEntry` (`modules/games/default.nix`)
and re-run `switch-apply-input`.

`switch-run-emulator` is the canonical entrypoint (generated Steam launchers use it; use it
manually too, e.g. for the one-time binding: `switch-run-emulator` with no ROM opens the GUI
with the menu bar visible). `SDL_JOYSTICK_HIDAPI=0` is also set — the virtual pad has no
hidraw node, so HIDAPI must not claim it. The wrapper also tees the emulator's stderr to
`~/.local/state/switch-emulator/stderr.log` (previous session kept as `stderr.log.old`):
native aborts — glibc's "stack smashing detected", .NET FailFast messages, driver asserts —
only print to stderr, which Steam swallows, so without this a native crash is silent and
leaves nothing but a coredump. (Diagnosed July 2026: TotK sessions died silently with
SIGABRT from a stack-canary failure inside coreclr's `sigsegv_handler`, and the message
was lost; check this log first when a game "just closes". Caveat: the same abort also
fires during *normal* teardown — even a clean quit-chord exit leaves an identical
SIGABRT coredump — so a Ryujinx coredump alone does not prove a mid-play crash.)

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

**Higher frame rate (not enabled)**

Some titles (e.g. Tears of the Kingdom) are engine-locked to 30 fps; unlocking is
possible but not wired up, because it needs two things the setup doesn't currently
have. Documented here so it's a small future step:

- **Game update.** The game must be updated to a mod-supported version (TotK: v1.2.1;
  base v1.0 has a save-loading bug above 30 fps). Updates are separate title-update
  NSPs — upload the NSP to the `emulation-roms` share and apply it via Ryujinx's title
  manager (persists in the synced data dir).
- **DynamicFPS mod.** Install the DynamicFPS mod (pin from `hoverbike1/TOTK-Mods-collection`)
  into `<dataDir>/mods/contents/<titleid>/` (TotK titleid `0100f2c0115b6000`). This is
  implementable declaratively as a `switch-refresh-mods` helper mirroring
  `switch-refresh-input` — fetched via Nix, copied in at activation. Mods live under the
  Syncthing-synced data dir, so they replicate to the controller too.
- **Ryujinx/stream:** keep vsync on (DynamicFPS decouples game speed from frame rate);
  the Sunshine stream is already 120 fps-capable, so no streaming changes are needed.

**Steps (all remote)**
1. Rebuild the host with `emulators.switch.enable = true`. On activation, `switch-refresh-keys`
   copies the keys into the data dir.
2. From any machine, mount `//controller/emulation-bios` (guest) and drop `prod.keys`
   (+ `title.keys`) in `switch/`; put ROMs on `//controller/emulation-roms` under
   `switch/<Game>/` (base `.xci` per folder).
3. Generate the Steam tiles: run `emulation-apply-shortcuts` over SSH — it stops Steam,
   copies keys, writes `shortcuts.vdf` for all systems, and (when
   `steamShortcuts.artwork.apiKeyFile` is configured) fetches SteamGridDB artwork.
   Reconnect the Moonlight "Steam Gaming" app to see them.
4. **One-time in Steam:** disable Steam Input so Steam releases its exclusive grab on the
   pad: Big Picture → Settings → Controller → turn off Steam Input for Xbox controllers
   (or per-tile: game tile → gear → Controller → Force Off).
5. **One-time per data dir:** launch a game; when Ryujinx prompts, install firmware (from the
   cartridge, or Tools → Install Firmware). It persists in `<dataDir>` (synced).
   The controller binding needs **no manual step**: `switch-apply-input` (run at activation
   and by `emulation-apply-shortcuts`) merges the verified Player 1 binding into
   `<dataDir>/Config.json`. Note the merge is a no-op until Ryujinx has run once and created
   `Config.json` — after the very first game launch, run `switch-apply-input` (or re-run
   `emulation-apply-shortcuts`) once.

**Artwork (SteamGridDB)**

When `emulators.steamShortcuts.artwork.apiKeyFile` is set, `emulation-apply-shortcuts`
also fetches artwork per game from SteamGridDB into each `userdata/<id>/config/grid/`
(for every system, not just Switch), named after the
shortcut's *unsigned* appid: `{appid}p` (portrait library tile), `{appid}` (wide capsule),
`{appid}_hero` (game-page banner), `{appid}_logo`, and `{appid}_icon` (also written into the
shortcut's `icon` vdf field). Behavior:

- **Key sourcing:** the key lives in nix-vault `secrets/common.yaml` (encrypted to *all*
  host keys, so any host/account can consume it) and is decrypted to
  `/run/secrets/steamgriddb-api-key` (owner `gamer`) on the desktop. One-time manual step:
  create an account at steamgriddb.com (Profile → Preferences → API), then in the nix-vault
  repo `sops secrets/common.yaml` and add `accounts.steamgriddb.apikey: <key>` — the
  existing `.sops.yaml` rule for `common.yaml` picks all recipients. Push, `nix flake update
  nix-vault`, rebuild.
- **Matching:** games are matched by folder name via SGDB's fuzzy autocomplete (first hit);
  the matched title is printed next to each folder name so mismatches are visible. To pin a
  wrong match, drop a `.sgdbid` file containing the SGDB game id into the game's ROM folder.
- **Idempotent & non-fatal:** existing grid files are kept (re-fetch with
  `EMU_ARTWORK_FORCE=1 emulation-apply-shortcuts`); a missing/unreadable key, an unmatched
  game, or any download error only prints a warning — shortcuts are always written.

**Notes / caveats**
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
- Switch emulation (`emulators.switch`) is pulled from `unstable` (ryubing carries a local source patch, `ryubing-sdl2-device-index.patch`, so it rebuilds from source). It ships helper scripts: `switch-refresh-keys` (copy keys from the BIOS share into the data dir), `switch-refresh-input` (install the Sunshine-pad SDL controller DB into the data dir), `switch-apply-input` (merge the verified Player 1 pad binding into `Config.json`, GUID-keyed and idempotent), and `switch-run-emulator` (canonical launch wrapper setting the SDL env vars and teeing stderr to `~/.local/state/switch-emulator/stderr.log`). Steam tiles are written by `emulation-apply-shortcuts` (see "Steam tiles for emulated systems"); `switch-apply-shortcuts` is a deprecated alias for it.
