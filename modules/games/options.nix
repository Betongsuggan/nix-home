{
  config,
  lib,
  pkgs,
  ...
}:
with lib;

{
  options.my.games = {
    enable = mkEnableOption "Enable gaming setup";

    mangohud = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable MangoHud overlay";
      };

      sessionWide = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Load MangoHud into every Vulkan app of the session (needed for the
          controller toggle in a streamed Big Picture session). Off: only
          games launched with `mangohud` (e.g. `mangohud %command%` in Steam),
          so ordinary apps don't load the overlay and poll sensors every frame.
        '';
      };

      detailedMode = mkOption {
        type = types.bool;
        default = true;
        description = "Show detailed system information in MangoHud";
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
            "mesen" # NES (most accurate core; NES .srm is raw SRAM, so saves carry over from fceumm)
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

        # Subtle per-core video shaders (slang, vulkan-compatible), auto-loaded
        # via <video_shader_dir>/presets/<CoreName>/<CoreName>.slangp, where
        # <CoreName> is the core's display name (library_name), e.g. "Snes9x".
        shaders = {
          enable = mkOption {
            type = types.bool;
            default = true;
            description = "Wire libretro slang shaders into RetroArch and auto-load per-core presets";
          };

          corePresets = mkOption {
            type = types.attrsOf (
              types.submodule {
                options = {
                  preset = mkOption {
                    type = types.str;
                    description = "Preset path relative to the shaders_slang root of pkgs.libretro-shaders-slang";
                  };
                  parameters = mkOption {
                    type = types.attrsOf types.str;
                    default = { };
                    description = ''
                      Shader parameter overrides (name -> value as string), written
                      after the #reference line — the same format RetroArch itself
                      uses when saving a simple preset. Parameter names/defaults:
                      `#pragma parameter` lines in the referenced .slang sources.
                    '';
                  };
                };
              }
            );
            default = {
              # Light CRT look: subtle scanlines, softened pixels, no curvature.
              # Subtler alternative: "pixel-art-scaling/sharp-bilinear.slangp".
              Snes9x = {
                preset = "crt/crt-easymode.slangp";
                # Toned down for large screens: halve scanline darkness, lift
                # the gap brightness floor, soften the phosphor dot mask, and
                # nudge sharpness down for slightly softened pixel edges.
                parameters = {
                  SCANLINE_STRENGTH = "0.50"; # default 1.0
                  SCANLINE_BRIGHT_MIN = "0.50"; # default 0.35
                  MASK_STRENGTH = "0.15"; # default 0.3
                  SHARPNESS_H = "0.35"; # default 0.5
                  SHARPNESS_V = "0.75"; # default 1.0
                };
              };
            };
            description = ''
              Core display name (library_name, e.g. "Snes9x") -> auto-loaded
              shader preset (+ optional parameter overrides) for that core.
            '';
          };
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
        # Duckstation was removed from nixpkgs 26.05 on upstream request. PSX is
        # covered by RetroArch's beetle-psx-hw core (in the default cores list),
        # so no standalone PSX emulator is installed.
      };

      # Nintendo Switch — pulled from `unstable` (like heroic) so we track the
      # fast-moving fork ecosystem. yuzu and the original Ryujinx were both
      # taken down by Nintendo in 2024; `ryubing` is the maintained Ryujinx
      # continuation and is the sensible default (Vulkan, stable, and its
      # `Ryujinx` binary boots straight into a game — ideal for per-game
      # Steam shortcuts). See the Switch first-time-setup section in SPEC.md.
      switch = {
        enable = mkEnableOption "Nintendo Switch emulation";

        emulator = mkOption {
          type = types.enum [
            "ryubing"
            "citron"
            "eden"
          ];
          default = "ryubing";
          description = "Switch emulator fork to install (from unstable for latest versions)";
        };

        dataDir = mkOption {
          type = types.str;
          default = "${config.home.homeDirectory}/${config.my.games.emulators.dataDir}/saves/switch";
          defaultText = "\${home}/\${emulators.dataDir}/saves/switch";
          description = ''
            Ryujinx `--root-data-dir`. Holds `system/` (keys) and `bis/`
            (firmware + saves). Lives under the synced saves tree so keys,
            firmware, and saves are backed up via Syncthing. Only used when
            emulator = "ryubing".
          '';
        };

        # Over Moonlight there is no keyboard and no Steam overlay (Steam Input
        # must stay off for the pad to reach Ryujinx), so a controller chord is
        # the only way to leave a game. A listener service watches the Sunshine
        # virtual pad and politely closes the Ryujinx window on the chord,
        # dropping the stream back to Big Picture.
        quitChord = {
          enable = mkOption {
            type = types.bool;
            default = true;
            description = "Hold Select+Start on the streamed gamepad to quit the running Switch game";
          };

          holdSeconds = mkOption {
            type = types.float;
            default = 1.5;
            description = "How long Select+Start must be held together before the game is closed";
          };
        };
      };

      # Per-ROM Steam tiles, written directly into shortcuts.vdf by
      # emulation-apply-shortcuts (add-shortcuts.py). Steam ROM Manager is
      # deliberately not used — its headless Electron CLI hangs on this host.
      # Default entries are generated for every enabled RetroArch core with a
      # known system mapping, plus Switch when emulators.switch is enabled;
      # hosts only need to flip `enable` (and can override/add systems).
      steamShortcuts = {
        enable = mkEnableOption "per-ROM Steam tiles written directly into shortcuts.vdf";

        artwork.apiKeyFile = mkOption {
          # str, not path: a path would copy the key into the world-readable
          # nix store. The file is read at runtime by emulation-apply-shortcuts.
          type = types.nullOr types.str;
          default = null;
          example = "/run/secrets/steamgriddb-api-key";
          description = ''
            Path to a file containing a SteamGridDB API key (typically a
            sops-nix /run/secrets path). When set, emulation-apply-shortcuts
            fetches grid artwork and icons per game from SteamGridDB.
            When null, shortcuts are created without artwork.
          '';
        };

        systems = mkOption {
          type = types.attrsOf (
            types.submodule (
              { name, ... }: {
                options = {
                  enable = mkOption {
                    type = types.bool;
                    default = true;
                    description = "Generate Steam tiles for this system";
                  };

                  romDir = mkOption {
                    type = types.str;
                    default = "${config.home.homeDirectory}/${config.my.games.emulators.dataDir}/roms/${name}";
                    defaultText = "\${home}/\${emulators.dataDir}/roms/<system>";
                    description = "Directory scanned for this system's ROMs";
                  };

                  extensions = mkOption {
                    type = types.listOf types.str;
                    description = "ROM file extensions (with leading dot, case-insensitive)";
                  };

                  layout = mkOption {
                    type = types.enum [
                      "flat"
                      "folder"
                    ];
                    default = "flat";
                    description = ''
                      "flat": one tile per ROM file in romDir (retro systems).
                      "folder": one tile per subdirectory, launching the base ROM
                      inside it, skipping (UPD)/(DLC) files (Switch layout).
                    '';
                  };

                  command = mkOption {
                    type = types.listOf types.str;
                    description = "Launch argv prefix; the ROM path is appended as the last argument";
                  };

                  windowClass = mkOption {
                    type = types.str;
                    default = "retroarch";
                    description = "Hyprland window class the launcher polls to fullscreen the emulator over Big Picture";
                  };

                  tag = mkOption {
                    type = types.str;
                    default = name;
                    description = "Steam collection tag applied to this system's tiles";
                  };

                  launcherDir = mkOption {
                    type = types.str;
                    default = "${config.home.homeDirectory}/.local/share/emulation-shortcuts/${name}";
                    defaultText = "~/.local/share/emulation-shortcuts/<system>";
                    description = ''
                      Where per-game launcher scripts are written. The shortcut
                      appid hashes the launcher path, so changing this orphans
                      existing artwork/collections/playtime for the system.
                    '';
                  };
                };
              }
            )
          );
          default = { };
          description = ''
            Systems to generate Steam tiles for. Merged over the generated
            defaults — override a field (`systems.snes.tag = ...`), disable a
            system (`systems.n64.enable = false`), or add a custom one.
          '';
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
}
