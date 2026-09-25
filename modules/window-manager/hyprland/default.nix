{
  config,
  lib,
  pkgs,
  ...
}:
with lib;

let
  wmLib = import ../lib.nix { inherit lib; };

  # my.window-manager.monitors in Hyprland's `monitor = name,mode,pos,scale,...`
  # syntax, plus a catch-all rule for unlisted outputs
  monitorRule =
    m:
    if !m.enable then
      "${m.name},disable"
    else
      concatStringsSep "," (
        [
          m.name
          (
            if m.mode == null then
              "preferred"
            else
              "${toString m.mode.width}x${toString m.mode.height}"
              + optionalString (m.mode.refresh != null) "@${wmLib.fmtNum m.mode.refresh}"
          )
          (if m.position == null then "auto" else "${toString m.position.x}x${toString m.position.y}")
          (wmLib.fmtNum m.scale)
        ]
        ++ optionals m.vrr [
          "vrr"
          "1"
        ]
        ++ optionals (m.bitdepth != null) [
          "bitdepth"
          (toString m.bitdepth)
        ]
        ++ optionals m.hdr [
          "cm"
          "hdr"
        ]
        ++ optionals (m.sdrBrightness != null) [
          "sdrbrightness"
          (wmLib.fmtNum m.sdrBrightness)
        ]
        ++ optionals (m.sdrSaturation != null) [
          "sdrsaturation"
          (wmLib.fmtNum m.sdrSaturation)
        ]
      );
  monitorRules = map monitorRule (wmLib.outputList config.my.window-manager.monitors) ++ [
    ",preferred,auto,1"
  ];

  # The shared keymap (my.window-manager.keybinds) as Hyprland binds
  hyprMod = {
    Mod = "SUPER";
    Ctrl = "CTRL";
    Shift = "SHIFT";
    Alt = "ALT";
  };
  hyprKey = {
    Return = "RETURN";
    Space = "SPACE";
    Minus = "minus";
    Equal = "equal";
    Comma = "comma";
    Period = "period";
  };
  hyprBind =
    chordName: e:
    let
      c = wmLib.chord chordName;
      how = wmLib.entryFor "hyprland" e;
      key = hyprKey.${c.key} or (if stringLength c.key == 1 then toLower c.key else c.key);
      dispatcher = if how ? spawn then "exec, ${wmLib.spawnString how.spawn}" else how.native;
    in
    optional (how != null) "${concatMapStringsSep "_" (m: hyprMod.${m}) c.mods}, ${key}, ${dispatcher}";
  keybindsWhere =
    pred:
    concatLists (mapAttrsToList hyprBind (filterAttrs (_: pred) config.my.window-manager.keybinds));

  # Niri-style maximize-column toggle for the scrolling layout: full column
  # width <-> the 0.5 default, staying tiled (borders/gaps kept) — unlike
  # `fullscreen, 1`, which enters maximize mode. The layout has no native
  # width toggle, so decide based on whether the focused window already spans
  # (nearly) the monitor's usable width.
  toggleColumnMaximize = pkgs.writeShellScriptBin "hypr-toggle-column-maximize" ''
    usable=$(${pkgs.hyprland}/bin/hyprctl -j monitors \
      | ${pkgs.jq}/bin/jq '.[] | select(.focused) | ((.width / .scale) - .reserved[0] - .reserved[2])')
    win=$(${pkgs.hyprland}/bin/hyprctl -j activewindow | ${pkgs.jq}/bin/jq '.size[0]')
    if ${pkgs.gawk}/bin/awk "BEGIN { exit !($win >= 0.93 * $usable) }"; then
      ${pkgs.hyprland}/bin/hyprctl dispatch layoutmsg "colresize 0.5"
    else
      ${pkgs.hyprland}/bin/hyprctl dispatch layoutmsg "colresize 1.0"
    fi
  '';

  # Steps through the focused monitor's open workspaces, clamped at the ends
  # (no wrap) — Hyprland's `workspace m±1` selector wraps via hardcoded modulo
  # with no config to disable it.
  workspaceStep = pkgs.writeShellScriptBin "hypr-workspace-step" ''
    # Usage: hypr-workspace-step <dispatcher> <+1|-1>
    dispatcher="$1"; step="$2"
    active=$(${pkgs.hyprland}/bin/hyprctl -j activeworkspace)
    target=$(${pkgs.hyprland}/bin/hyprctl -j workspaces | ${pkgs.jq}/bin/jq \
      --argjson active "$active" --argjson step "$step" '
      [ .[] | select(.monitor == $active.monitor and .id > 0) | .id ] | sort
      | . as $ids
      | ($ids | index($active.id)) as $i
      | $ids[[[ $i + $step, 0 ] | max, (($ids | length) - 1)] | min]')
    exec ${pkgs.hyprland}/bin/hyprctl dispatch "$dispatcher" "$target"
  '';

  # Lid switch handling, gated on external displays (mirrors the logind config
  # in power-management): with an external monitor connected, lid close just
  # disables the internal panel so work continues on the external screen
  # (logind ignores the lid in that case); with the panel alone, lock and
  # blank before logind suspends. Lid open re-enables the panel from its
  # config rules.
  lidSwitch = pkgs.writeShellScriptBin "hypr-lid-switch" ''
    # Usage: hypr-lid-switch <close|open>
    hyprctl() { ${pkgs.hyprland}/bin/hyprctl "$@"; }
    internal=$(hyprctl -j monitors all \
      | ${pkgs.jq}/bin/jq -r '[.[] | select(.name | startswith("eDP"))][0].name // empty')
    externals=$(hyprctl -j monitors all \
      | ${pkgs.jq}/bin/jq '[.[] | select(.name | startswith("eDP") | not)] | length')
    case "$1" in
      close)
        # Only act when an external monitor is present. With the panel alone,
        # logind suspends (HandleLidSwitch) and hypridle locks via its
        # before-sleep hook under a sleep inhibitor; spawning hyprlock or
        # blanking here races the suspend freeze and can leave the panel
        # black on resume.
        if [ "$externals" -gt 0 ]; then
          [ -n "$internal" ] && hyprctl keyword monitor "$internal, disable"
        fi
        ;;
      open)
        [ -n "$internal" ] && hyprctl keyword monitor "$internal, enable"
        hyprctl dispatch dpms on
        ;;
    esac
  '';

  # Guards against the zero-monitor state: if the internal panel was disabled
  # by hypr-lid-switch and the last external monitor is then unplugged (lid
  # still closed), Hyprland is left with no enabled outputs and wedges. Watch
  # socket2 for monitorremoved; when no externals remain, re-enable the panel
  # and — if the lid is closed — suspend, matching the "no monitor + closed
  # lid = sleep" semantics that logind can't provide here (unplugging isn't a
  # lid event).
  monitorWatch = pkgs.writeShellScriptBin "hypr-monitor-watch" ''
    hyprctl() { ${pkgs.hyprland}/bin/hyprctl "$@"; }
    export HYPRLAND_INSTANCE_SIGNATURE=''${HYPRLAND_INSTANCE_SIGNATURE:-$(${pkgs.coreutils}/bin/ls -t "$XDG_RUNTIME_DIR/hypr" | ${pkgs.coreutils}/bin/head -1)}
    # Only monitor removals reach the shell loop; the socket carries every
    # focus/workspace event
    ${pkgs.socat}/bin/socat -u "UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" - \
    | ${pkgs.gnugrep}/bin/grep --line-buffered '^monitorremoved' \
    | while IFS= read -r event; do
      case "$event" in
        monitorremoved*)
          externals=$(hyprctl -j monitors all \
            | ${pkgs.jq}/bin/jq '[.[] | select(.name | startswith("eDP") | not)] | length')
          [ "$externals" -gt 0 ] && continue
          internal=$(hyprctl -j monitors all \
            | ${pkgs.jq}/bin/jq -r '[.[] | select(.name | startswith("eDP")) | select(.disabled)][0].name // empty')
          [ -n "$internal" ] || continue
          hyprctl keyword monitor "$internal, enable"
          hyprctl dispatch dpms on
          if ${pkgs.gnugrep}/bin/grep -qs closed /proc/acpi/button/lid/*/state; then
            ${pkgs.systemd}/bin/systemctl suspend
          fi
          ;;
      esac
    done
  '';
in
{
  options.my.window-manager.hyprland = {
    enable = mkEnableOption "Enable Hyprland";
    lockscreen.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable lockscreen functionality (hyprlock, idle lock, etc.)";
    };
    cmFsPassthrough = mkOption {
      type = types.int;
      default = 2;
      description = "Fullscreen CM passthrough (0=off, 1=always, 2=HDR-only)";
    };
    windowRules = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Additional Hyprland window rules (unified 0.55 windowrule format, e.g. \"float on, match:class ^(foo)$\")";
    };
    workspaceRules = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Additional Hyprland workspace rules";
    };
  };

  config = mkIf config.my.window-manager.hyprland.enable {
    # Multi-gestures
    # services.touchegg.enable = true;  # TODO: Move to system level

    # On battery, skip the blur and shadow passes (extra GPU work on every
    # redraw); back on when plugged in
    my.battery-monitor.onBattery = [
      "${pkgs.hyprland}/bin/hyprctl --batch 'keyword decoration:blur:enabled false; keyword decoration:shadow:enabled false'"
    ];
    my.battery-monitor.onAC = [
      "${pkgs.hyprland}/bin/hyprctl --batch 'keyword decoration:blur:enabled true; keyword decoration:shadow:enabled true'"
    ];

    home = {
      # name/package/size come from stylix (stylix.cursor in the theming
      # module); hyprcursor is the only part stylix doesn't manage.
      pointerCursor.hyprcursor = {
        enable = true;
        inherit (config.my.theming.cursor) size;
      };
      packages = with pkgs; [
        # Helpers the keymap's Hyprland actions call
        toggleColumnMaximize
        workspaceStep
        hyprlock
        grim
        slurp
        wl-clipboard
        systemd
      ];
    };

    # Screen-share restore tokens: Electron apps (Slack) re-request the portal
    # for every thumbnail refresh, popping hyprland-share-picker over and over
    # (upstream: xdg-desktop-portal-hyprland#11, "allow the restore token and
    # on recent xdph versions it won't show up multiple times"). This
    # pre-checks the picker's restore-token checkbox so follow-up requests
    # reuse the selected stream silently. The picker itself still appears for
    # every NEW selection — full monitor/window choice is kept.
    # XDPH reads this at startup; restart xdg-desktop-portal-hyprland after
    # changing it.
    xdg.configFile."hypr/xdph.conf".text = ''
      screencopy {
        allow_token_by_default = true
      }
    '';

    services.hyprpaper = {
      enable = true;
      # hyprpaper ≥0.8 config format: wallpaper is a block keyed by monitor
      # (empty = all monitors). The pre-0.8 `preload`/`wallpaper = ,path`
      # lines are silently ignored, leaving monitors with "no target".
      settings = {
        splash = false;
        wallpaper = {
          monitor = "";
          path = "${config.my.theming.wallpaper}";
        };
      };
    };

    services.hypridle = {
      enable = true;
      settings = {
        general = {
          after_sleep_cmd = "${pkgs.hyprland}/bin/hyprctl dispatch dpms on";
          ignore_dbus_inhibit = false;
        }
        // (
          if config.my.window-manager.hyprland.lockscreen.enable then
            {
              lock_cmd = "${pkgs.procps}/bin/pgrep -x hyprlock || ${pkgs.hyprlock}/bin/hyprlock";
              before_sleep_cmd = "${pkgs.systemd}/bin/loginctl lock-session";
            }
          else
            { }
        );

        listener = [
          {
            timeout = config.my.window-manager.idle.dimAfter;
            on-timeout = "${pkgs.brightnessctl}/bin/brightnessctl -s set 10";
            on-resume = "${pkgs.brightnessctl}/bin/brightnessctl -r";
          }
        ]
        ++ (
          if config.my.window-manager.hyprland.lockscreen.enable then
            [
              {
                timeout = config.my.window-manager.idle.lockAfter;
                on-timeout = "${pkgs.systemd}/bin/loginctl lock-session";
              }
            ]
          else
            [ ]
        )
        ++ [
          {
            timeout = config.my.window-manager.idle.screenOffAfter;
            on-timeout = "${pkgs.hyprland}/bin/hyprctl dispatch dpms off";
            on-resume = "${pkgs.hyprland}/bin/hyprctl dispatch dpms on";
          }
          {
            timeout = config.my.window-manager.idle.suspendAfter;
            on-timeout = "${pkgs.systemd}/bin/systemctl suspend";
          }
        ];
      };
    };

    # Bind hypridle to hyprland-session.target so it restarts when Hyprland restarts
    # (e.g., after nixos-rebuild switch)
    systemd.user.services.hypridle = {
      Unit = {
        BindsTo = [ "hyprland-session.target" ];
        After = [ "hyprland-session.target" ];
      };
    };

    # See monitorWatch above: recovers from unplugging the last external
    # monitor while the lid is closed (internal panel disabled).
    systemd.user.services.hypr-monitor-watch = {
      Unit = {
        Description = "Re-enable internal panel when the last external monitor is removed";
        BindsTo = [ "hyprland-session.target" ];
        After = [ "hyprland-session.target" ];
      };
      Service = {
        ExecStart = "${monitorWatch}/bin/hypr-monitor-watch";
        Restart = "on-failure";
      };
      Install.WantedBy = [ "hyprland-session.target" ];
    };

    programs.hyprlock = mkIf config.my.window-manager.hyprland.lockscreen.enable {
      enable = true;
      settings = {
        general = {
          hide_cursor = true;
        };

        # No fade in/out (the pre-0.7 no_fade_in/no_fade_out options are gone)
        animations = {
          enabled = false;
        };

        auth = {
          fingerprint = {
            enabled = true;
            ready_message = "Scan fingerprint to unlock";
            present_message = "Scanning...";
          };
        };

        background = [
          {
            path = "${config.my.theming.wallpaper}";
            blur_passes = 2;
            blur_size = 4;
          }
        ];

        input-field = [
          {
            size = "300, 50";
            outline_thickness = 2;
            dots_size = 0.2;
            dots_spacing = 0.5;
            outer_color = "rgb(${lib.strings.removePrefix "#" config.my.theming.colors.primary.foreground})";
            inner_color = "rgb(${lib.strings.removePrefix "#" config.my.theming.colors.primary.background})";
            font_color = "rgb(${lib.strings.removePrefix "#" config.my.theming.colors.primary.foreground})";
            fade_on_empty = false;
            placeholder_text = "<i>$FPRINTPROMPT</i>";
            hide_input = false;
            position = "0, -50";
            halign = "center";
            valign = "center";
          }
        ];

        label = [
          {
            text = "$TIME";
            color = "rgb(${lib.strings.removePrefix "#" config.my.theming.colors.primary.foreground})";
            font_size = 64;
            font_family = "monospace";
            position = "0, 150";
            halign = "center";
            valign = "center";
          }
        ];
      };
    };

    wayland.windowManager.hyprland = {
      enable = true;
      # Keep the hyprlang config format — the settings below are hyprlang
      # attrs; the new "lua" default (stateVersion >= 26.05) would change how
      # the config is generated.
      configType = "hyprlang";
      systemd.variables = [ "--all" ];
      settings = {
        monitor = monitorRules;

        # Workspace to monitor bindings + user workspace rules
        workspace =
          (map (
            wb:
            "${toString wb.workspace}, monitor:${wb.monitor}" + (if wb.default then ", default:true" else "")
          ) config.my.window-manager.workspaceBindings)
          ++ config.my.window-manager.hyprland.workspaceRules;

        cursor = {
          enable_hyprcursor = false;
        };

        exec-once = [
          # Launcher daemons (walker, vicinae) are started via systemd services
        ]
        # Create persistent virtual/headless monitors at startup as a fast path.
        # A dedicated systemd-user unit (see modules/game-streaming/system.nix)
        # is the authoritative creator and is what sunshine.service orders
        # against — these exec-once lines just shorten the window in the common
        # case where Hyprland's IPC comes up immediately.
        ++ (map (
          name: "${pkgs.hyprland}/bin/hyprctl output create headless ${name}"
        ) config.my.window-manager.virtualMonitors)
        # Autostart applications
        ++ builtins.concatLists (
          builtins.attrValues (
            builtins.mapAttrs (
              name: app:
              if app == null then
                [ ]
              else
                let
                  # Autostart applications on provided worspace
                  workspacePrefix = if app.workspace != null then "[workspace ${toString app.workspace}] " else "";
                in
                [ "${workspacePrefix}${app.command}" ]
            ) config.my.window-manager.autostartApps
          )
        );

        general = {
          "col.active_border" =
            "rgb(${lib.strings.removePrefix "#" config.my.theming.colors.primary.foreground})";
          # Built-in scrollable-tiling layout (Hyprland ≥0.55), mimicking niri:
          # windows are columns on an infinite horizontal strip.
          layout = "scrolling";
          # Without this, movefocus at the strip end probes from the opposite
          # monitor edge — i.e. wraps to the first column. niri stops instead.
          no_focus_fallback = true;
        };

        # Defaults already match niri (column_width 0.5, presets
        # 0.333/0.5/0.667/1.0, follow_focus); niri does not wrap focus or
        # column movement at the strip ends, so disable wrapping.
        scrolling = {
          wrap_focus = false;
          wrap_swapcol = false;
        };

        # Kept for workspaces explicitly opting back into dwindle via rules.
        dwindle = {
          force_split = 2;
        };

        animations = {
          animation = [
            # Workspaces slide vertically like niri's stacked-workspace visual
            # (also flips the workspace swipe gesture to vertical).
            "workspaces, 1, 6, default, slidevert"
          ];
        };

        decoration = {
          rounding = config.my.theming.cornerRadius;
        };

        bind = keybindsWhere (e: !(e.repeat or false));
        binds = {
          movefocus_cycles_fullscreen = true;
          # Don't hop focus to the adjacent monitor at the strip end — niri
          # stops there too (it uses dedicated monitor binds instead).
          window_direction_monitor_fallback = false;
        };
        binde = keybindsWhere (e: e.repeat or false);

        # Lid switch bindings: external-display-aware lock/panel handling
        bindl = lib.optionals config.my.window-manager.hyprland.lockscreen.enable [
          ", switch:on:Lid Switch, exec, ${lidSwitch}/bin/hypr-lid-switch close"
          ", switch:off:Lid Switch, exec, ${lidSwitch}/bin/hypr-lid-switch open"
        ];

        render = {
          cm_enabled = true;
          # cm_fs_passthrough was removed in Hyprland 0.55 (fullscreen HDR
          # passthrough is now automatic via render:cm_auto_hdr). The
          # cmFsPassthrough option is kept for back-compat but no longer emitted.
        };

        # Unified windowrule syntax (Hyprland 0.55): comma-separated fields of
        # `match:<prop> <value>` and `<effect> <value>`; every field takes a
        # value (booleans are truthy strings like "on"). windowrulev2 is a hard
        # error in 0.55 and its rules are NOT applied.
        windowrule = [
          # xdg-desktop-portal-hyprland's screen-share picker is a dialog, not
          # a tile — float it (upstream-recommended rule).
          "float on, match:class ^(hyprland-share-picker)$"
          "center on, match:class ^(hyprland-share-picker)$"
          # Browsers' "<site> is sharing your screen" indicator bubble: tiled
          # into a column it can't be clicked or dismissed — float it instead.
          "float on, match:title ^(.* is sharing (your screen|a window|a tab)\\.?)$"
        ]
        ++ config.my.window-manager.hyprland.windowRules;

        misc = {
          disable_splash_rendering = true;
          # vfr moved to debug: in Hyprland 0.55 and defaults to on — no longer set here.
        };

        debug = {
          enable_stdout_logs = true;
          disable_logs = false;
        };

        # Hyprland ≥0.51 gesture syntax (the old gestures:workspace_swipe
        # toggle is gone; the tuning options below remain). Workspaces stack
        # vertically (slidevert), so the 3-finger workspace swipe is vertical,
        # like niri. Horizontally, 3 fingers step focus through the scrolling
        # layout's columns — discrete dispatcher gestures, since no smooth
        # layout-scroll action exists.
        gesture = [
          "3, vertical, workspace"
          "3, left, dispatcher, movefocus, l"
          "3, right, dispatcher, movefocus, r"
        ];

        gestures = {
          # Viewport follows the fingers (swipe down = workspace below),
          # inverted from the content-follows-fingers default. Flip this (and
          # swap the left/right gestures above) for the opposite feel.
          workspace_swipe_invert = false;
        };

        input = {
          kb_layout = "us";
          kb_variant = "colemak";
          kb_options = "caps:escape,compose:${config.my.window-manager.composeKey}";
          resolve_binds_by_sym = 1;

          touchpad = {
            natural_scroll = false;
            disable_while_typing = true;
            scroll_factor = 1.0;
          };

          sensitivity = 0;
          accel_profile = "flat";
        }
        // optionalAttrs (config.my.window-manager.touchOutput != null) {
          touchdevice = {
            output = config.my.window-manager.touchOutput;
          };
        };
      };
    };
  };
}
