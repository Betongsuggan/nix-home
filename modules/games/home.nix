# Gaming module — unified console-like experience via Steam Big Picture
#
# The goal is that ALL games — native Steam, third-party stores, and emulated
# ROMs — appear as launchable entries inside Steam's gamepad UI. This turns a
# Linux PC into a console: one interface, one controller, no keyboard needed.
#
# How it all fits together:
#
#   Steam (native games)
#     Already there. Steam is the shell; native and Proton games just work.
#
#   Heroic / Lutris / Bottles (Epic, GOG, Ubisoft, Battle.net)
#     Installed via tools.enable. These manage their own game libraries but
#     are invisible to Steam by default.
#     -> BoilR (steamIntegration) scans Heroic/Lutris/etc. and creates
#        non-Steam shortcuts in your Steam library, complete with artwork.
#        Run it once, then re-run whenever you add games to those stores.
#
#   Emulated ROMs (retro consoles + Nintendo Switch)
#     ROMs live in ~/emulation/roms/{system}/ (or your configured dataDir).
#     RetroArch handles older systems (NES through Saturn) via libretro cores;
#     standalone emulators cover systems that need them (PS2, GameCube, PSP).
#     -> emulation-apply-shortcuts (emulators.steamShortcuts) writes one Steam
#        shortcut per ROM directly into shortcuts.vdf, with per-game artwork
#        from SteamGridDB. Steam ROM Manager is NOT used: its headless Electron
#        CLI hangs on this host (see SPEC.md). The generator is driven by a
#        Nix-built JSON manifest (per system: ROM dir, extensions, launch
#        command, window class, Steam tag) consumed by add-shortcuts.py.
#
#   Nintendo Switch (emulators.switch)
#     Emulator (default Ryubing) pulled from unstable. Keys are copied from the
#     controller BIOS share into Ryujinx's data dir; ROMs are read live from the
#     roms/switch share (mounted cache=none — see emulation-client). Switch is
#     just another steamShortcuts system entry (folder layout, .xci), with
#     extra key/firmware/controller plumbing. Firmware + controller are a
#     one-time Ryujinx-UI setup persisted in the synced data dir. See SPEC.md.
#
# First-time setup after a fresh build:
#
#   1. Place BIOS files in ~/emulation/bios/ (flat, where RetroArch cores look)
#   2. Place ROMs in ~/emulation/roms/{snes,nes,gba,n64,psx,...}/
#   3. Run emulation-apply-shortcuts (stops Steam, writes the tiles + artwork)
#   4. Open BoilR, let it scan Heroic/Lutris libraries, apply to Steam
#   5. Restart Steam — all games now appear in Big Picture / gamepad UI
#
# After adding new games:
#   - New store games: re-run BoilR
#   - New ROMs: re-run emulation-apply-shortcuts
#   - New Steam games: nothing to do, they appear automatically
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.my.games;
in
{
  imports = [
    ./options.nix
    ./mangohud.nix
    ./emulation.nix
  ];

  config = mkIf cfg.enable {
    home.packages =
      with pkgs;
      [
        chiaki
        discord
        evtest
        gamemode
        lutris
        # Not `steam`: it comes from programs.steam (nixos.nix), whose wrapper
        # carries the Proton-GE compat-tool paths; a copy here would shadow it
        steam-run
        sc-controller
        vulkan-tools
        mesa-demos
        # For launchers outside Steam (Lutris, Bottles); Steam games use
        # Proton-GE. Staging patchset in WoW64 mode (32-bit programs run in
        # the 64-bit build); unlike wineWowPackages, Hydra builds it
        wineWow64Packages.staging
      ]
      ++ (optionals cfg.tools.enable [
        protonup-qt # imperative extra Proton-GE builds (next to protonGE.packages)
        winetricks
        goverlay # MangoHud/vkBasalt GUI
        bottles # Wine prefix manager
        unstable.heroic # GOG/Epic launcher (stable pulls insecure electron-39)
      ])
      ++ (optionals cfg.vkbasalt.enable [
        vkbasalt
      ])
      # Steam library integration — BoilR writes non-Steam shortcuts for store
      # launchers (Heroic/Lutris/etc.) into shortcuts.vdf. Steam ROM Manager is
      # installable but unused for ROMs: its headless CLI hangs on this host —
      # emulation-apply-shortcuts covers per-ROM tiles instead.
      ++ (optionals cfg.steamIntegration.enable (
        (optional cfg.steamIntegration.boilr boilr)
        ++ (optional cfg.steamIntegration.steamRomManager steam-rom-manager)
      ));
  };
}
