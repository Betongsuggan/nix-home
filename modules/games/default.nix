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
#   Emulated ROMs (retro consoles)
#     ROMs live in ~/emulation/roms/{system}/ (or your configured dataDir).
#     RetroArch handles older systems (NES through Saturn) via libretro cores.
#     Standalone emulators handle systems that need them (PS2, GameCube, PSP).
#     -> Steam ROM Manager (steamIntegration) creates an individual Steam
#        shortcut for each ROM, with per-game artwork from SteamGridDB.
#        Configure one parser per system, point it at the ROM directory and
#        the right emulator executable, then run to generate shortcuts.
#
# First-time setup after a fresh build:
#
#   1. Place BIOS files in ~/emulation/bios/ (RetroArch, PCSX2, etc. need them)
#   2. Place ROMs in ~/emulation/roms/{snes,nes,gba,n64,ps2,...}/
#   3. Open Steam ROM Manager, add a parser per system, generate shortcuts
#   4. Open BoilR, let it scan Heroic/Lutris libraries, apply to Steam
#   5. Restart Steam — all games now appear in Big Picture / gamepad UI
#
# After adding new games:
#   - New store games: re-run BoilR
#   - New ROMs: re-run Steam ROM Manager
#   - New Steam games: nothing to do, they appear automatically
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

{
  options.games = {
    enable = mkEnableOption "Enable gaming setup";

    mangohud = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable MangoHud overlay";
      };

      detailedMode = mkOption {
        type = types.bool;
        default = true;
        description = "Show detailed system information in MangoHud";
      };

      controllerToggle = mkOption {
        type = types.bool;
        default = false;
        description = "Enable controller-based MangoHud toggle (deprecated - use controller module instead)";
      };

      position = mkOption {
        type = types.enum [
          "top-left"
          "top-right"
          "bottom-left"
          "bottom-right"
          "top-center"
          "bottom-center"
        ];
        default = "top-left";
        description = "MangoHud overlay position";
      };

      fontSize = mkOption {
        type = types.int;
        default = 24;
        description = "MangoHud font size";
      };
    };

    vkbasalt = {
      enable = mkEnableOption "vkBasalt post-processing";
    };

    protonGE = {
      enable = mkEnableOption "Proton-GE";
    };

    tools = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Install gaming tools (goverlay, protonup-qt, etc.)";
      };
    };

    # Emulation backend — provides the actual emulators that Steam ROM Manager
    # will point its shortcuts at. RetroArch covers older systems via libretro
    # cores; standalone emulators cover systems that benefit from dedicated apps.
    emulators = {
      enable = mkEnableOption "emulators (RetroArch + standalone)";

      dataDir = mkOption {
        type = types.str;
        default = "emulation";
        description = "Directory name under $HOME for emulation data (ROMs, saves, BIOS)";
      };

      retroarch = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable RetroArch with libretro cores";
        };

        cores = mkOption {
          type = types.listOf types.str;
          default = [
            "snes9x" # SNES
            "fceumm" # NES
            "mgba" # GB, GBC, GBA
            "mupen64plus" # N64
            "melonds" # NDS
            "beetle-psx-hw" # PSX
            "genesis-plus-gx" # Mega Drive, Master System
            "flycast" # Dreamcast
            "beetle-saturn" # Saturn
            "fbneo" # Arcade
          ];
          description = "List of libretro core names to include with RetroArch";
        };
      };

      standalone = {
        pcsx2 = mkOption {
          type = types.bool;
          default = true;
          description = "Install PCSX2 (PS2 emulator)";
        };
        dolphin = mkOption {
          type = types.bool;
          default = true;
          description = "Install Dolphin (GameCube/Wii emulator)";
        };
        ppsspp = mkOption {
          type = types.bool;
          default = true;
          description = "Install PPSSPP (PSP emulator)";
        };
        duckstation = mkOption {
          type = types.bool;
          default = true;
          description = "Install Duckstation (PSX emulator)";
        };
      };
    };

    # The glue that makes everything appear in Steam Big Picture:
    # - BoilR: imports Heroic/Lutris/Bottles games as non-Steam shortcuts
    # - Steam ROM Manager: creates per-ROM shortcuts with artwork
    # Both are run-once tools — they modify Steam's shortcuts.vdf, then Steam
    # picks up the changes on next restart.
    steamIntegration = {
      enable = mkEnableOption "Steam library integration (BoilR + Steam ROM Manager)";

      boilr = mkOption {
        type = types.bool;
        default = true;
        description = "Install BoilR to import games from Heroic/Lutris/etc. into Steam";
      };

      steamRomManager = mkOption {
        type = types.bool;
        default = true;
        description = "Install Steam ROM Manager to create per-ROM Steam shortcuts with artwork";
      };
    };
  };

  config = let cfg = config.games; in mkIf cfg.enable {
    programs.mangohud = mkIf cfg.mangohud.enable {
      enable = true;
      enableSessionWide = true;
      settings = {
        # Performance metrics
        fps = true;
        frametime = true;
        frame_timing = true;

        # GPU information
        gpu_stats = true;
        gpu_temp = true;
        gpu_junction_temp = true;
        gpu_mem_temp = true;
        gpu_power = true;
        gpu_fan = true;
        gpu_core_clock = true;
        gpu_mem_clock = true;
        gpu_name = cfg.mangohud.detailedMode;
        gpu_voltage = true;

        # CPU information
        cpu_stats = true;
        cpu_temp = true;
        cpu_power = true;
        cpu_mhz = cfg.mangohud.detailedMode;
        core_load = cfg.mangohud.detailedMode;

        # Memory information
        vram = true;
        ram = true;
        swap = cfg.mangohud.detailedMode;
        procmem = cfg.mangohud.detailedMode;

        # Gaming features
        fsr = true;
        hdr = true;
        refresh_rate = true;
        show_fps_limit = true;
        present_mode = true;
        gamemode = true;
        vkbasalt = cfg.vkbasalt.enable;
        winesync = true;

        # System information
        throttling_status = true;
        vulkan_driver = true;
        engine_version = cfg.mangohud.detailedMode;
        wine = true;
        resolution = true;
        arch = cfg.mangohud.detailedMode;
        display_server = cfg.mangohud.detailedMode;

        # Controller battery
        device_battery = "gamepad";
        device_battery_icon = true;

        # Time and system status
        time = true;
        time_format = "%H:%M:%S";
        version = cfg.mangohud.detailedMode;

        # Network and IO (for detailed mode)
        network = mkIf cfg.mangohud.detailedMode true;
        io_read = mkIf cfg.mangohud.detailedMode true;
        io_write = mkIf cfg.mangohud.detailedMode true;

        # Visual settings
        position = cfg.mangohud.position;
        font_size = cfg.mangohud.fontSize;
        text_outline = true;
        text_outline_thickness = 1.5;
        round_corners = 8;

        # Toggle keybind (Shift+F9 avoids game F-key conflicts)
        toggle_hud = "Shift_R+F9";

        # Start hidden by default (toggle with controller)
        no_display = true;

        # Color scheme
        text_color = "FFFFFF";
        gpu_color = "2E9762";
        cpu_color = "2E97CB";
        vram_color = "AD64C1";
        ram_color = "C26693";
        frametime_color = "00FF00";
        background_color = "020202";
        background_alpha = 0.8;
      };
    };

    home.packages = with pkgs;
      [
        chiaki
        discord
        evtest
        gamemode
        lutris
        steam
        steam-run
        sc-controller
        vulkan-tools
        mesa-demos
      ]
      ++ (optionals cfg.tools.enable [
        protonup-qt # Proton-GE version manager
        winetricks
        protontricks
        goverlay # MangoHud/vkBasalt GUI
        bottles # Wine prefix manager
        heroic # GOG/Epic launcher
      ])
      ++ (optionals cfg.vkbasalt.enable [
        vkbasalt
      ])
      # RetroArch — the emulation backend for older systems (NES through Saturn).
      # Uses retroarch-bare.wrapper to bake in cores and path settings declaratively
      # via --appendconfig, while still allowing runtime tweaks (config_save_on_exit).
      # Steam ROM Manager will create shortcuts that launch:
      #   retroarch -L /nix/store/.../snes9x_libretro.so "/path/to/rom.sfc"
      ++ (optionals (cfg.emulators.enable && cfg.emulators.retroarch.enable) [
        (retroarch-bare.wrapper {
          cores = map (name: libretro.${name}) cfg.emulators.retroarch.cores;
          settings = {
            savefile_directory = "${config.home.homeDirectory}/${cfg.emulators.dataDir}/saves";
            savestate_directory = "${config.home.homeDirectory}/${cfg.emulators.dataDir}/states";
            system_directory = "${config.home.homeDirectory}/${cfg.emulators.dataDir}/bios";
            content_directory = "${config.home.homeDirectory}/${cfg.emulators.dataDir}/roms";
            input_joypad_driver = "udev";
            video_driver = "vulkan";
            video_fullscreen = "true";
            menu_driver = "ozone";
            config_save_on_exit = "true";
          };
        })
      ])
      # Standalone emulators for systems where dedicated apps outperform RetroArch
      # cores (better accuracy, HDR support, per-game settings, etc.).
      # Steam ROM Manager shortcuts for these use the emulator's own CLI, e.g.:
      #   pcsx2 "/path/to/game.iso"
      ++ (optionals cfg.emulators.enable (
        (optional cfg.emulators.standalone.pcsx2 pcsx2)
        ++ (optional cfg.emulators.standalone.dolphin dolphin-emu)
        ++ (optional cfg.emulators.standalone.ppsspp ppsspp)
        ++ (optional cfg.emulators.standalone.duckstation duckstation)
      ))
      # Steam library integration — these tools write non-Steam shortcuts into
      # Steam's shortcuts.vdf so everything shows up in Big Picture / gamepad UI.
      # BoilR handles store launchers; Steam ROM Manager handles individual ROMs.
      ++ (optionals cfg.steamIntegration.enable (
        (optional cfg.steamIntegration.boilr boilr)
        ++ (optional cfg.steamIntegration.steamRomManager steam-rom-manager)
      ));

    # Install Proton-GE to Steam's compatibility tools directory
    home.file = mkIf cfg.protonGE.enable {
      ".steam/root/compatibilitytools.d/proton-ge".source = pkgs.proton-ge-bin;
    };
  };
}
