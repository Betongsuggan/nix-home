# Emulation: RetroArch and standalone emulators, the Nintendo Switch
# emulator and its helpers, and the per-ROM Steam shortcuts. These share one
# set of derived values (paths, launch commands, the RetroArch wrapper), so
# they live together. See home.nix for the overview.
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.my.games;
  sw = cfg.emulators.switch;
  switchEnabled = cfg.emulators.enable && sw.enable;
  isRyujinx = sw.emulator == "ryubing";

  # Ryubing 1.3.3 opens controllers by their position in its own filtered
  # gamepad list, but SDL_GameControllerOpen expects SDL's device index,
  # which also counts non-gamepad joysticks (G13 thumbstick, Sunshine's
  # mouse/pen passthrough nodes). On this host the Sunshine virtual pad
  # never sits at index 0, so Ryujinx opened the wrong device, got NULL,
  # and silently dropped the pad from its Input list. The patch resolves
  # the real SDL index via the joystick instance id.
  switchPkg =
    if isRyujinx then
      pkgs.unstable.${sw.emulator}.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [ ./ryubing-sdl2-device-index.patch ];
      })
    else
      pkgs.unstable.${sw.emulator};
  switchBin =
    {
      ryubing = "Ryujinx";
      citron = "citron";
      eden = "eden";
    }
    .${sw.emulator};

  ss = cfg.emulators.steamShortcuts;
  shortcutsEnabled = cfg.emulators.enable && ss.enable;
  retroarchEnabled = cfg.emulators.enable && cfg.emulators.retroarch.enable;

  emuDir = "${config.home.homeDirectory}/${cfg.emulators.dataDir}";
  switchRomDir = "${emuDir}/roms/switch";
  # Keys + firmware come from the controller BIOS Samba share, auto-mounted
  # read-only at ~/emulation/bios (see emulation-mounts).
  switchKeysDir = "${emuDir}/bios/switch";

  # RetroArch autoconfig profile for the Sunshine virtual pad. Its udev
  # device name/ids never match anything in the upstream autoconfig DB
  # (the GUID trick that broke SDL, see switchControllerDb above, applies
  # here too), so without this the pad can't navigate the Ozone menu
  # deterministically. Button/axis indices follow the evdev/xpad order —
  # the same layout verified live for switchControllerDb (A=0 B=1 X=2 Y=3,
  # back=6 start=7 guide=8, sticks a0/a1 + a3/a4, triggers a2/a5, dpad on
  # hat0). Note RetroPad convention: input_b is the BOTTOM face button
  # (physical A), so b/a and y/x are cross-assigned on purpose.
  sunshinePadAutoconfig = pkgs.writeTextDir "share/libretro/autoconfig/udev/Sunshine X-Box One (virtual) pad.cfg" ''
    input_driver = "udev"
    input_device = "Sunshine X-Box One (virtual) pad"
    input_vendor_id = "1118"
    input_product_id = "746"
    input_b_btn = "0"
    input_a_btn = "1"
    input_y_btn = "2"
    input_x_btn = "3"
    input_l_btn = "4"
    input_r_btn = "5"
    input_select_btn = "6"
    input_start_btn = "7"
    input_menu_toggle_btn = "8"
    input_l3_btn = "9"
    input_r3_btn = "10"
    input_l2_axis = "+2"
    input_r2_axis = "+5"
    input_l_x_plus_axis = "+0"
    input_l_x_minus_axis = "-0"
    input_l_y_plus_axis = "+1"
    input_l_y_minus_axis = "-1"
    input_r_x_plus_axis = "+3"
    input_r_x_minus_axis = "-3"
    input_r_y_plus_axis = "+4"
    input_r_y_minus_axis = "-4"
    input_up_btn = "h0up"
    input_down_btn = "h0down"
    input_left_btn = "h0left"
    input_right_btn = "h0right"
  '';

  # Upstream autoconfig DB (physical pads keep working) + the Sunshine
  # profile. The wrapper's default joypad_autoconfig_dir points at the
  # upstream DB only, so we join and override.
  retroarchAutoconfigDir = pkgs.symlinkJoin {
    name = "retroarch-autoconfig-with-sunshine-pad";
    paths = [
      pkgs.retroarch-joypad-autoconfig
      sunshinePadAutoconfig
    ];
  };

  # One store dir per core preset: presets/<CoreName>/<CoreName>.slangp with
  # a #reference to the real preset. #reference points at the ORIGINAL
  # store path, so the preset's internal relative shader paths resolve
  # against real files regardless of symlinkJoin layout. writeTextFile (not
  # writeTextDir) so core names with spaces still yield a valid drv name.
  shaderCorePresets = mapAttrsToList (
    coreName: p:
    pkgs.writeTextFile {
      name = "retroarch-auto-preset-${strings.sanitizeDerivationName coreName}";
      destination = "/share/libretro/shaders/presets/${coreName}/${coreName}.slangp";
      # Parameter overrides after #reference — the exact layout RetroArch
      # writes when saving a "simple preset" in-menu.
      text = ''
        #reference "${pkgs.libretro-shaders-slang}/share/libretro/shaders/shaders_slang/${p.preset}"
      ''
      + concatStrings (
        mapAttrsToList (param: value: ''
          ${param} = "${value}"
        '') p.parameters
      );
    }
  ) cfg.emulators.retroarch.shaders.corePresets;

  # Full upstream slang collection (browsable in-menu) overlaid with the
  # generated presets/ auto-load dir — same pattern as retroarchAutoconfigDir.
  retroarchShaderDir = pkgs.symlinkJoin {
    name = "retroarch-shaders-with-auto-presets";
    paths = [ pkgs.libretro-shaders-slang ] ++ shaderCorePresets;
  };

  # Hoisted (rather than inline in home.packages) so the Steam-tile launch
  # commands below reference the exact same wrapped binary + core set.
  retroarchPkg = pkgs.retroarch-bare.wrapper {
    cores = map (name: pkgs.libretro.${name}) cfg.emulators.retroarch.cores;
    settings = {
      # Must match the provisioned layout inside the Syncthing-synced
      # saves tree (emulation-client creates saves/retroarch/{saves,states}
      # and the server mirrors it) — anything outside ~/emulation/saves
      # is never synced or backed up.
      savefile_directory = "${emuDir}/saves/retroarch/saves";
      savestate_directory = "${emuDir}/saves/retroarch/states";
      # Cross-device save contract (shared with the Ayn Thor through the
      # emulation-saves Syncthing folder): flat layout — no per-core or
      # per-content subdirs — so both devices resolve the same .srm from
      # the same ROM filename. The Thor's RetroArch must mirror these
      # (see modules/games/SPEC.md "Cross-device save sync").
      sort_savefiles_enable = "false";
      sort_savestates_enable = "false";
      sort_savefiles_by_content_enable = "false";
      sort_savestates_by_content_enable = "false";
      savefiles_in_content_dir = "false";
      savestates_in_content_dir = "false";
      # Flush SaveRAM every 60s (default: only on content close) so saves
      # survive crashes and reach the other device without waiting for a
      # clean quit.
      autosave_interval = "60";
      # Read-only CIFS mount; fine for the default cores, which only read
      # BIOS files from it (flat, e.g. scph5501.bin). Cores that write into
      # the system dir are deliberately not in the default tile set.
      system_directory = "${emuDir}/bios";
      content_directory = "${emuDir}/roms";
      input_joypad_driver = "udev";
      video_driver = "vulkan";
      video_fullscreen = "true";
      menu_driver = "ozone";
      config_save_on_exit = "true";
      joypad_autoconfig_dir = "${retroarchAutoconfigDir}/share/libretro/autoconfig";
      # Streamed sessions have no keyboard, so quitting must be a pad
      # chord — and it must be a RetroPad *combo*, not raw button indices:
      # raw indices differ per pad (Sunshine pad: 6/7 = Back/Start; a
      # locally-connected DualSense: 6/7 = L2/R2 — raw-index hotkeys made
      # squeezing the triggers quit the game). Combos are resolved after
      # autoconfig, so Start+Select means the same physical chord on every
      # controller (mirrors the Switch quitChord; clean exit flushes SRAM
      # to the synced saves dir). Menu toggle comes from each pad's
      # autoconfig profile: Guide on the Sunshine pad, PS on a DualSense.
      input_quit_gamepad_combo = "4"; # INPUT_COMBO_START_SELECT
      quit_press_twice = "false";
      # Tombstones: these raw-index hotkeys were previously declared here,
      # and config_save_on_exit persisted them into retroarch.cfg — merely
      # REMOVING a key from this set doesn't undo that (appendconfig only
      # overrides declared keys), so the stale values kept applying (on a
      # DualSense 6/7/8 = L2/R2/Create → triggers quit the game). "nul" is
      # RetroArch's unbind value; per-pad menu toggles from autoconfig
      # profiles still apply. Never delete a key from this set — tombstone
      # it.
      input_enable_hotkey_btn = "nul";
      input_exit_emulator_btn = "nul";
      input_menu_toggle_btn = "nul";
      # Menu is otherwise controllable only by the pad on port 0; with
      # more than one joystick-tagged device present, let any pad drive it.
      input_all_users_control_menu = "true";
    }
    // (
      if cfg.emulators.retroarch.shaders.enable then
        {
          # Per-core shaders: video_shader_dir's presets/ subdir is one of the
          # auto-preset search roots (lowest priority — presets the user saves
          # in-menu under ~/.config/retroarch/config/<Core>/ still win).
          # video_shader_enable defaults to FALSE on desktop and gates all
          # shader loading.
          video_shader_dir = "${retroarchShaderDir}/share/libretro/shaders";
          auto_shaders_enable = "true";
          video_shader_enable = "true";
        }
      else
        {
          # Tombstones (never delete a declared key — see SPEC.md): reset to
          # RetroArch defaults; "default" is the canonical reset value for
          # directory settings.
          video_shader_dir = "default";
          auto_shaders_enable = "true";
          video_shader_enable = "false";
        }
    );
  };

  # Core .so filenames don't always match their nixpkgs attr names. Paths
  # resolve inside the wrapper's core dir, so a tile can only launch cores
  # that are actually installed.
  coreFile = {
    snes9x = "snes9x_libretro.so";
    mesen = "mesen_libretro.so";
    fceumm = "fceumm_libretro.so";
    mgba = "mgba_libretro.so";
    mupen64plus = "mupen64plus_next_libretro.so";
    "beetle-psx-hw" = "mednafen_psx_hw_libretro.so";
    "genesis-plus-gx" = "genesis_plus_gx_libretro.so";
  };
  raCmd = core: [
    "${retroarchPkg}/bin/retroarch"
    "-L"
    "${retroarchPkg}/lib/retroarch/cores/${coreFile.${core}}"
  ];
  hasCore = core: retroarchEnabled && elem core cfg.emulators.retroarch.cores;

  # Default Steam-tile systems: one entry per enabled RetroArch core with a
  # known mapping. Deferred on purpose: nds/dreamcast/saturn/arcade cores
  # need writable or subdirectory BIOS layouts that the read-only flat BIOS
  # mount doesn't provide, and standalone emulators (PS2/GC/PSP) each need
  # their own controller/save-path validation first — all become one-entry
  # additions here once solved.
  retroSystemDefaults =
    optionalAttrs (hasCore "snes9x") {
      snes = {
        extensions = [
          ".sfc"
          ".smc"
          ".zip"
        ];
        command = raCmd "snes9x";
        tag = "SNES";
      };
    }
    // optionalAttrs (hasCore "mesen" || hasCore "fceumm") {
      nes = {
        extensions = [
          ".nes"
          ".zip"
        ];
        # Mesen preferred (accuracy); fceumm honored for hosts that keep it
        # in their cores list instead.
        command = raCmd (if hasCore "mesen" then "mesen" else "fceumm");
        tag = "NES";
      };
    }
    // optionalAttrs (hasCore "mgba") {
      gb = {
        extensions = [
          ".gb"
          ".zip"
        ];
        command = raCmd "mgba";
        tag = "Game Boy";
      };
      gbc = {
        extensions = [
          ".gbc"
          ".zip"
        ];
        command = raCmd "mgba";
        tag = "Game Boy Color";
      };
      gba = {
        extensions = [
          ".gba"
          ".zip"
        ];
        command = raCmd "mgba";
        tag = "Game Boy Advance";
      };
    }
    // optionalAttrs (hasCore "mupen64plus") {
      n64 = {
        extensions = [
          ".n64"
          ".z64"
          ".v64"
          ".zip"
        ];
        command = raCmd "mupen64plus";
        tag = "Nintendo 64";
      };
    }
    // optionalAttrs (hasCore "beetle-psx-hw") {
      psx = {
        # .m3u > .cue > .chd stem-dedup in add-shortcuts.py keeps
        # multi-disc/multi-track games as a single tile.
        extensions = [
          ".m3u"
          ".cue"
          ".chd"
          ".pbp"
        ];
        command = raCmd "beetle-psx-hw";
        tag = "PlayStation";
      };
    }
    // optionalAttrs (hasCore "genesis-plus-gx") {
      megadrive = {
        extensions = [
          ".md"
          ".gen"
          ".bin"
          ".zip"
        ];
        command = raCmd "genesis-plus-gx";
        tag = "Mega Drive";
      };
      mastersystem = {
        extensions = [
          ".sms"
          ".zip"
        ];
        command = raCmd "genesis-plus-gx";
        tag = "Master System";
      };
    };

  switchSystemDefault = optionalAttrs switchEnabled {
    switch = {
      romDir = switchRomDir;
      extensions = [ ".xci" ];
      layout = "folder";
      command = [ "${switchRunEmulator}/bin/switch-run-emulator" ];
      windowClass = "Ryujinx";
      tag = "Nintendo Switch";
      # Legacy dir from the Switch-only pipeline: the shortcut appid hashes
      # the launcher path, so keeping it preserves existing Switch tiles'
      # artwork, collections, and playtime.
      launcherDir = "${config.home.homeDirectory}/.local/share/switch-shortcuts";
    };
  };

  # Copy the Switch keys from the BIOS share into Ryujinx's data dir as real
  # local files. (Symlinking to the lazily-automounted CIFS share is fragile
  # at launch; a local copy is always readable.) Firmware is NOT provisioned
  # here: dropping raw NCAs into registered/ does not register with Ryujinx
  # ("No firmware installed") and would clobber a proper install. Instead do
  # a one-time firmware install via the Ryujinx UI (from a game cartridge, or
  # Tools → Install Firmware pointed at the bios/switch dump); it persists in
  # the synced data dir. Only relevant for the ryubing (Ryujinx) emulator.
  switchRefreshKeys = pkgs.writeShellScriptBin "switch-refresh-keys" ''
    set -euo pipefail
    SYS_DIR="${sw.dataDir}/system"
    mkdir -p "$SYS_DIR"
    if [ -r "${switchKeysDir}/prod.keys" ]; then
      cp -Lf "${switchKeysDir}/prod.keys" "$SYS_DIR/prod.keys"
      [ -r "${switchKeysDir}/title.keys" ] && cp -Lf "${switchKeysDir}/title.keys" "$SYS_DIR/title.keys"
      echo "Copied Switch keys into $SYS_DIR"
    else
      echo "No prod.keys at ${switchKeysDir} yet — upload keys to the controller bios/switch share, then re-run switch-refresh-keys."
    fi
  '';

  # SDL gamecontroller mapping for the Sunshine virtual pad. Its GUID embeds
  # a CRC of the device name ("Sunshine X-Box One (virtual) pad") and a
  # nonstandard version, so SDL's built-in database never matches it and
  # SDL classifies it "joystick but not gamecontroller" — invisible to
  # Ryujinx. Ryujinx natively loads <dataDir>/SDL_GameControllerDB.txt at
  # startup, so shipping the mapping there fixes every invocation. Layout
  # is the standard Linux xpad layout (verified against the live device).
  # Second line = same GUID with the name-CRC zeroed, as a fallback in
  # case a Sunshine update changes the device name.
  switchControllerDb = pkgs.writeText "SDL_GameControllerDB.txt" ''
    # Sunshine virtual X-Box One pad (managed by modules/games; do not edit)
    03008d205e040000ea02000008040000,Sunshine Virtual Pad,a:b0,b:b1,x:b2,y:b3,back:b6,guide:b8,start:b7,leftstick:b9,rightstick:b10,leftshoulder:b4,rightshoulder:b5,dpup:h0.1,dpdown:h0.4,dpleft:h0.8,dpright:h0.2,leftx:a0,lefty:a1,rightx:a3,righty:a4,lefttrigger:a2,righttrigger:a5,platform:Linux,
    030000005e040000ea02000008040000,Sunshine Virtual Pad,a:b0,b:b1,x:b2,y:b3,back:b6,guide:b8,start:b7,leftstick:b9,rightstick:b10,leftshoulder:b4,rightshoulder:b5,dpup:h0.1,dpdown:h0.4,dpleft:h0.8,dpright:h0.2,leftx:a0,lefty:a1,rightx:a3,righty:a4,lefttrigger:a2,righttrigger:a5,platform:Linux,
  '';

  switchRefreshInput = pkgs.writeShellScriptBin "switch-refresh-input" ''
    set -euo pipefail
    mkdir -p "${sw.dataDir}"
    install -m 644 "${switchControllerDb}" "${sw.dataDir}/SDL_GameControllerDB.txt"
    echo "Installed Sunshine pad mapping into ${sw.dataDir}/SDL_GameControllerDB.txt"
  '';

  # Known-good Player1 -> Sunshine pad binding (verified in-game). The id is
  # what ryubing's SDL2GamepadDriver.GenerateGamepadId produces for the pad:
  # "0-" + the SDL GUID as a .NET Guid string with the name-CRC nibbles
  # zeroed. Schema mirrors GenericControllerInputConfig (snake_case).
  switchInputEntry = pkgs.writeText "sunshine-pad-input.json" (
    builtins.toJSON {
      version = 1;
      backend = "GamepadSDL2";
      id = "0-00000003-045e-0000-ea02-000008040000";
      name = "Sunshine Virtual Pad";
      controller_type = "ProController";
      player_index = "Player1";
      deadzone_left = 0.1;
      deadzone_right = 0.1;
      range_left = 1.0;
      range_right = 1.0;
      trigger_threshold = 0.5;
      left_joycon_stick = {
        joystick = "Left";
        stick_button = "LeftStick";
        invert_stick_x = false;
        invert_stick_y = false;
        rotate90_cw = false;
      };
      right_joycon_stick = {
        joystick = "Right";
        stick_button = "RightStick";
        invert_stick_x = false;
        invert_stick_y = false;
        rotate90_cw = false;
      };
      left_joycon = {
        button_minus = "Minus";
        button_l = "LeftShoulder";
        button_zl = "LeftTrigger";
        button_sl = "Unbound";
        button_sr = "Unbound";
        dpad_up = "DpadUp";
        dpad_down = "DpadDown";
        dpad_left = "DpadLeft";
        dpad_right = "DpadRight";
      };
      right_joycon = {
        button_plus = "Plus";
        button_r = "RightShoulder";
        button_zr = "RightTrigger";
        button_sl = "Unbound";
        button_sr = "Unbound";
        # Direct 1:1 (Nintendo-label) mapping: the pad's A/B/X/Y drive the Switch
        # A/B/X/Y of the same name, so the printed letters match in-game actions.
        # (ryubing's default position-swaps A/B and X/Y, which put actions on the
        # wrong buttons — e.g. jump landing on Y instead of X.)
        button_a = "A";
        button_b = "B";
        button_x = "X";
        button_y = "Y";
      };
      motion = {
        motion_backend = "GamepadDriver";
        sensitivity = 100;
        gyro_deadzone = 1;
        enable_motion = false;
      };
      rumble = {
        strong_rumble = 1.0;
        weak_rumble = 1.0;
        enable_rumble = false;
      };
      led = {
        enable_led = false;
        turn_off_led = false;
        use_rainbow = false;
        led_color = 0;
      };
    }
  );

  # Merge ONLY the Player1 binding into Config.json, keyed by the pad's
  # GUID — idempotent, and everything else in the file (graphics settings,
  # firmware state, UI prefs) passes through untouched, so it neither
  # clobbers runtime changes nor fights the Syncthing-synced data dir.
  switchApplyInput = pkgs.writeShellScriptBin "switch-apply-input" ''
    set -euo pipefail
    CFG="${sw.dataDir}/Config.json"
    GUID="00000003-045e-0000-ea02-000008040000"
    if [ ! -f "$CFG" ]; then
      echo "No Config.json at $CFG yet — start a game (or switch-run-emulator) once, then re-run switch-apply-input."
      exit 0
    fi
    cp -f "$CFG" "$CFG.bak"
    ${pkgs.jq}/bin/jq --slurpfile entry ${switchInputEntry} --arg guid "$GUID" '
      .input_config = ((.input_config // [])
        | map(select((.id // "") | contains($guid) | not))
        + $entry)
    ' "$CFG" > "$CFG.tmp"
    mv -f "$CFG.tmp" "$CFG"
    echo "Player1 -> Sunshine pad binding merged into $CFG (backup: $CFG.bak)"
  '';

  # Canonical way to start the emulator: forces SDL's direct /dev/input
  # scan (the udev enumeration path misses the hotplugged Sunshine pad)
  # and skips HIDAPI (the virtual pad has no hidraw node). Used by the
  # generated Steam launchers and for manual/binding sessions alike.
  switchRunEmulator = pkgs.writeShellScriptBin "switch-run-emulator" ''
    export SDL_JOYSTICK_DISABLE_UDEV=1
    export SDL_JOYSTICK_HIDAPI=0
    # Native aborts (glibc "stack smashing detected", .NET FailFast, driver
    # asserts) go to stderr, which Steam swallows — without this the process
    # dies silently and only a coredump remains. Kept out of the synced data
    # dir to avoid Syncthing churn; previous session's log survives as .old.
    STDERR_LOG="''${XDG_STATE_HOME:-$HOME/.local/state}/switch-emulator/stderr.log"
    mkdir -p "$(dirname "$STDERR_LOG")"
    [ -f "$STDERR_LOG" ] && mv -f "$STDERR_LOG" "$STDERR_LOG.old"
    exec ${switchPkg}/bin/${switchBin} ${lib.optionalString isRyujinx ''--root-data-dir "${sw.dataDir}" ''}"$@" 2> >(${pkgs.coreutils}/bin/tee "$STDERR_LOG" >&2)
  '';

  # Quit-chord listener: hold Select+Start on the Sunshine virtual pad to
  # close the running game. Reads the pad's evdev node directly (the pad is
  # hotplugged by Sunshine on first input, so the device is re-discovered
  # in a poll loop). Closing goes through `hyprctl dispatch closewindow`
  # (same as clicking the window's X, so Ryujinx shuts down cleanly), with
  # a SIGTERM fallback if the window ignores it.
  switchQuitListener = pkgs.replaceVars ./switch-quit-listener.py {
    holdSeconds = toString sw.quitChord.holdSeconds;
    hyprctl = "${pkgs.hyprland}/bin/hyprctl";
    pgrep = "${pkgs.procps}/bin/pgrep";
    pkill = "${pkgs.procps}/bin/pkill";
  };

  # Steam shortcut generation. Steam ROM Manager's headless CLI hangs on
  # this setup (Electron never returns after "Fetching parsers...", under
  # both Xvfb and an attached Wayland session), so instead of SRM we write
  # shortcuts.vdf directly with a tiny Python+vdf script. Deterministic,
  # needs no display/GPU/D-Bus, and idempotent (upserts by app name).
  pyEnv = pkgs.python3.withPackages (ps: [ ps.vdf ]);

  # Nix-built manifest consumed by add-shortcuts.py: per system the ROM
  # dir, extensions, layout, launch argv, Hyprland window class, and Steam
  # tag. Hosts extend/override via emulators.steamShortcuts.systems.
  shortcutsManifest = pkgs.writeText "emulation-shortcuts.json" (
    builtins.toJSON {
      hyprctl = "${pkgs.hyprland}/bin/hyprctl";
      artworkKeyFile = if ss.artwork.apiKeyFile == null then "" else ss.artwork.apiKeyFile;
      systems = mapAttrs (_: s: {
        inherit (s)
          romDir
          extensions
          layout
          command
          windowClass
          tag
          launcherDir
          ;
      }) (filterAttrs (_: s: s.enable) ss.systems);
    }
  );

  # Stop Steam (so it doesn't clobber shortcuts.vdf on exit), run the
  # Switch pre-hooks when enabled, then upsert one Steam shortcut per game
  # across all manifest systems (pruning tiles whose ROM disappeared).
  emulationApplyShortcuts = pkgs.writeShellScriptBin "emulation-apply-shortcuts" ''
    set -euo pipefail
    # Reach the running Steam in the user's graphical session (needed when
    # invoked over SSH) so -shutdown actually stops it; otherwise Steam
    # would rewrite shortcuts.vdf from memory on its next exit.
    export XDG_RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
    echo "Stopping Steam (so it doesn't overwrite shortcuts.vdf on exit)..."
    ${pkgs.steam}/bin/steam -shutdown >/dev/null 2>&1 || true
    for _ in $(seq 1 20); do
      ${pkgs.procps}/bin/pgrep -x steam >/dev/null || break
      sleep 1
    done
    # Fallback if it's still up after the graceful shutdown window.
    ${pkgs.procps}/bin/pgrep -x steam >/dev/null && ${pkgs.procps}/bin/pkill -TERM -u "$(id -u)" steam || true
    sleep 2
    ${optionalString switchEnabled ''
      ${switchRefreshKeys}/bin/switch-refresh-keys || true
      ${switchRefreshInput}/bin/switch-refresh-input || true
      ${switchApplyInput}/bin/switch-apply-input || true
    ''}
    echo "Writing Steam shortcuts..."
    EMU_MANIFEST=${shortcutsManifest} \
    EMU_ARTWORK_FORCE="''${EMU_ARTWORK_FORCE:-''${SWITCH_ARTWORK_FORCE:-}}" \
      ${pyEnv}/bin/python3 ${./add-shortcuts.py}
    echo "Reconnect the Moonlight 'Steam Gaming' app to see the tiles."
  '';

  # Back-compat alias from the Switch-only pipeline.
  switchApplyShortcuts = pkgs.writeShellScriptBin "switch-apply-shortcuts" ''
    echo "switch-apply-shortcuts is deprecated; running emulation-apply-shortcuts (all systems)." >&2
    exec ${emulationApplyShortcuts}/bin/emulation-apply-shortcuts "$@"
  '';
in
{
  config = mkIf cfg.enable {
    # Generated per-system Steam-tile defaults (retro systems from the enabled
    # RetroArch cores when steamShortcuts is on; Switch whenever it's enabled,
    # matching the pre-manifest behavior). Every field is mkDefault'd so hosts
    # can override piecemeal via emulators.steamShortcuts.systems.<name>.
    my.games.emulators.steamShortcuts.systems = mapAttrs (_: s: mapAttrs (_: mkDefault) s) (
      (optionalAttrs shortcutsEnabled retroSystemDefaults) // switchSystemDefault
    );

    home.packages =
      with pkgs;
      # RetroArch — the emulation backend for older systems (NES through Saturn).
      # Uses retroarch-bare.wrapper (hoisted into the let so the Steam-tile
      # launchers run the same binary) to bake in cores, paths, the Sunshine-pad
      # autoconfig, and the Select+Start quit chord declaratively via
      # --appendconfig, while still allowing runtime tweaks (config_save_on_exit
      # persists undeclared keys; declared keys re-win on every launch).
      (optionals retroarchEnabled [ retroarchPkg ])
      # Standalone emulators for systems where dedicated apps outperform RetroArch
      # cores (better accuracy, HDR support, per-game settings, etc.). Not yet
      # wired into steamShortcuts — each needs controller/save-path validation.
      ++ (optionals cfg.emulators.enable (
        (optional cfg.emulators.standalone.pcsx2 pcsx2)
        ++ (optional cfg.emulators.standalone.dolphin dolphin-emu)
        ++ (optional cfg.emulators.standalone.ppsspp ppsspp)
      ))
      # Per-ROM Steam tiles: installed for steamShortcuts, and kept for plain
      # switch.enable so the pre-manifest Switch-only workflow still works.
      ++ (optionals (cfg.emulators.enable && (ss.enable || switchEnabled)) [
        emulationApplyShortcuts
      ])
      # Nintendo Switch: the emulator (from unstable) plus the shortcut/firmware
      # helper scripts (switch-apply-shortcuts writes shortcuts.vdf directly).
      ++ (optionals switchEnabled [
        switchPkg
        switchApplyShortcuts
        switchApplyInput
        switchRefreshKeys
        switchRefreshInput
        switchRunEmulator
      ]);

    # Switch setup: copy keys from the BIOS share into Ryujinx's data dir.
    # Steam shortcuts are generated on demand by switch-apply-shortcuts (which
    # must stop Steam first), not at activation time. Firmware is a one-time
    # Ryujinx UI install (see modules/games/SPEC.md), persisted in the data dir.
    home.activation.switchSetup = mkIf switchEnabled (
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        ${switchRefreshKeys}/bin/switch-refresh-keys || true
        ${switchRefreshInput}/bin/switch-refresh-input || true
        ${switchApplyInput}/bin/switch-apply-input || true
      ''
    );

    # Quit-chord listener (Select+Start held -> close the running game).
    # Same service shape as controller-mangohud-toggle in modules/controller.
    systemd.user.services.switch-quit-listener = mkIf (switchEnabled && sw.quitChord.enable) {
      Unit = {
        Description = "Quit Switch games via Select+Start on the streamed gamepad";
        After = [ "graphical-session.target" ];
      };

      Service = {
        Type = "simple";
        ExecStart = "${pkgs.python3}/bin/python3 ${switchQuitListener}";
        Restart = "always";
        RestartSec = "5s";
      };

      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };
}
