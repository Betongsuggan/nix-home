{
  config,
  lib,
  pkgs,
  ...
}:
with lib;

let
  cfg = config.my.window-manager;
  launcher = config.my.launcher;

  # Name of the focused output, per compositor (for recording/screenshots)
  focusedOutput =
    {
      hyprland = "${pkgs.hyprland}/bin/hyprctl monitors -j | ${pkgs.jq}/bin/jq -r '.[] | select(.focused) | .name'";
      niri = "${config.programs.niri.package}/bin/niri msg --json focused-output | ${pkgs.jq}/bin/jq -r .name";
      sway = "${pkgs.sway}/bin/swaymsg -t get_outputs | ${pkgs.jq}/bin/jq -r '.[] | select(.focused) | .name'";
      i3 = "";
    }
    .${cfg.backend};

  # Where captures go: subfolders of the XDG Pictures and Videos folders
  screenshotDir = "${config.xdg.userDirs.pictures}/Screenshots";
  recordingDir = "${config.xdg.userDirs.videos}/Recordings";

  # `screen-record region|output`: toggles a wf-recorder capture of a selected
  # region or the focused output into the recordings folder
  screenRecord = pkgs.writeShellScriptBin "screen-record" ''
    if ${pkgs.procps}/bin/pkill -SIGINT wf-recorder; then
      ${config.my.notifications.send {
        category = "recording";
        icon = "media-playback-stop";
        summary = "Recording stopped";
      }}
      exit 0
    fi
    case "$1" in
      region) geometry=$(${pkgs.slurp}/bin/slurp) || exit 0; target=(-g "$geometry") ;;
      *) target=(-o "$(${focusedOutput})") ;;
    esac
    ${config.my.notifications.send {
      category = "recording";
      summary = "Recording started";
    }}
    exec ${pkgs.wf-recorder}/bin/wf-recorder "''${target[@]}" -c libx264 -p crf=23 -p preset=fast \
      --pixel-format yuv420p -f "${recordingDir}/$(${pkgs.coreutils}/bin/date -Iseconds).mkv"
  '';

  # `screenshot region|output` into the screenshots folder (wlroots
  # compositors; niri uses its built-in screenshot UI instead)
  screenshot = pkgs.writeShellScriptBin "screenshot" ''
    file="${screenshotDir}/$(${pkgs.coreutils}/bin/date -Iseconds).png"
    case "$1" in
      region) geometry=$(${pkgs.slurp}/bin/slurp) || exit 0; exec ${pkgs.grim}/bin/grim -g "$geometry" "$file" ;;
      *) exec ${pkgs.grim}/bin/grim -o "$(${focusedOutput})" "$file" ;;
    esac
  '';

  # Launcher menus the chosen launcher backend doesn't provide are null
  launch = f: args: if launcher.${f} == null then null else launcher.${f} args;

  workspaceKeys = genList (i: {
    n = i + 1;
    key = toString (mod (i + 1) 10);
  }) 10;
in
{
  imports = [
    ./hyprland
    ./i3
    ./niri
    ./sway
  ];

  options.my.window-manager = {
    enable = mkEnableOption "Enable window manager configuration";

    screenshotDir = mkOption {
      type = types.str;
      readOnly = true;
      default = screenshotDir;
      description = "Folder screenshots are saved to (for backends with their own screenshot tool)";
    };

    backend = mkOption {
      description = "Window manager backend to use";
      type = types.enum [
        "hyprland"
        "i3"
        "niri"
        "sway"
      ];
      default = "hyprland";
    };

    autostartApps = mkOption {
      description = "Applications to autostart, with optional workspace assignment";
      type = types.attrsOf (
        types.nullOr (
          types.submodule {
            options = {
              command = mkOption {
                type = types.str;
                description = "Command to execute";
                example = "firefox";
              };

              workspace = mkOption {
                type = types.nullOr types.int;
                description = "Workspace number to launch the application in (null for no specific workspace)";
                default = null;
                example = 1;
              };
            };
          }
        )
      );
      default = { };
    };

    monitors = mkOption {
      description = ''
        Outputs by connector name (e.g. "DP-2", or a virtual monitor such as
        "SUNSHINE"). Outputs not listed use their highest resolution at its
        highest refresh rate on Hyprland (the preferred mode elsewhere),
        automatic position and scale 1. Each backend renders this in its own format.
      '';
      type = types.attrsOf (
        types.submodule {
          options = {
            enable = mkOption {
              type = types.bool;
              default = true;
              description = "Whether to use this output at all.";
            };
            mode = mkOption {
              type = types.nullOr (
                types.submodule {
                  options = {
                    width = mkOption { type = types.int; };
                    height = mkOption { type = types.int; };
                    refresh = mkOption {
                      type = types.nullOr types.number;
                      default = null;
                      description = "Refresh rate in Hz (null: the mode's default).";
                    };
                  };
                }
              );
              default = null;
              description = "Resolution and refresh rate; null picks the highest resolution and refresh rate (Hyprland) or the preferred mode.";
            };
            position = mkOption {
              type = types.nullOr (
                types.submodule {
                  options = {
                    x = mkOption { type = types.int; };
                    y = mkOption { type = types.int; };
                  };
                }
              );
              default = null;
              description = "Position in the global layout; null places it automatically.";
            };
            scale = mkOption {
              type = types.number;
              default = 1;
            };
            vrr = mkOption {
              type = types.bool;
              default = false;
              description = "Variable refresh rate.";
            };
            hdr = mkOption {
              type = types.bool;
              default = false;
              description = "HDR color management (Hyprland).";
            };
            bitdepth = mkOption {
              type = types.nullOr types.int;
              default = null;
              description = "Output bit depth, e.g. 10 (Hyprland).";
            };
            sdrBrightness = mkOption {
              type = types.nullOr types.number;
              default = null;
              description = "SDR content brightness in HDR mode (Hyprland).";
            };
            sdrSaturation = mkOption {
              type = types.nullOr types.number;
              default = null;
              description = "SDR content saturation in HDR mode (Hyprland).";
            };
          };
        }
      );
      default = { };
      example = literalExpression ''
        {
          DP-2 = {
            mode = { width = 3440; height = 1440; refresh = 240; };
            hdr = true;
            bitdepth = 10;
          };
          HDMI-A-1.enable = false;
        }
      '';
    };

    virtualMonitors = mkOption {
      description = ''
        Virtual/headless monitor names to create at window manager startup.
        Useful for streaming (e.g., Sunshine) without a physical display connected.

        Configure its mode in the regular `monitors` option, e.g.:
          monitors.SUNSHINE.mode = { width = 1920; height = 1080; refresh = 60; };
          virtualMonitors = [ "SUNSHINE" ];
      '';
      type = types.listOf types.str;
      default = [ ];
      example = [ "SUNSHINE" ];
    };

    workspaceBindings = mkOption {
      description = "Bind workspaces to specific monitors";
      type = types.listOf (
        types.submodule {
          options = {
            workspace = mkOption {
              type = types.int;
              description = "Workspace number";
              example = 10;
            };
            monitor = mkOption {
              type = types.str;
              description = "Monitor name (e.g., DP-1, SUNSHINE)";
              example = "DP-1";
            };
            default = mkOption {
              type = types.bool;
              default = false;
              description = "Make this the default workspace for the monitor";
            };
          };
        }
      );
      default = [ ];
      example = [
        {
          workspace = 10;
          monitor = "SUNSHINE";
          default = true;
        }
      ];
    };

    composeKey = mkOption {
      type = types.str;
      default = "ralt";
      description = ''
        Keyboard key to use as the compose key for typing special characters.

        Available options:
        - ralt: Right Alt key (default)
        - lalt: Left Alt key
        - rwin: Right Windows/Super key
        - lwin: Left Windows/Super key
        - menu: Menu key
        - rctrl: Right Control key
        - lctrl: Left Control key
        - caps: Caps Lock key
        - prsc: Print Screen key
        - sclk: Scroll Lock key

        Common choices are 'ralt' (Right Alt) or 'menu' (Menu key).

        The compose key allows you to type special characters by pressing
        the compose key followed by a sequence of keys. For example, with
        Swedish character mappings, Compose+o+o produces ö.
      '';
      example = "menu";
    };

    idle = {
      dimAfter = mkOption {
        type = types.int;
        default = 240;
        description = "Seconds of inactivity before the backlight dims to 10%.";
      };
      lockAfter = mkOption {
        type = types.int;
        default = 300;
        description = "Seconds before the session locks (when the backend's lockscreen is on).";
      };
      screenOffAfter = mkOption {
        type = types.int;
        default = 330;
        description = "Seconds before the outputs are powered off.";
      };
      suspendAfter = mkOption {
        type = types.int;
        default = 900;
        description = "Seconds before the machine suspends.";
      };
    };

    keybinds = mkOption {
      internal = true;
      readOnly = true;
      type = types.attrsOf types.attrs;
      description = ''
        The shared keymap, keyed by chord in niri notation ("Mod+Shift+P").
        Each entry is either `{ spawn = <shell string or argv list>; }`, run
        the same way everywhere, or native actions per compositor
        (`{ hyprland = "dispatcher, args"; niri = { <action> = ...; }; sway =
        "command"; i3 = "command"; }`); a compositor without an entry leaves
        the chord unbound. `repeat = true` repeats while held; `spawn = null`
        (e.g. a launcher menu the backend lacks) is skipped.
      '';
    };

    touchOutput = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Output name to map touchscreen input to. Set to null to disable
        touchscreen output mapping (uses default behavior).
        Common values: "eDP-1" for laptop displays.
      '';
      example = "eDP-1";
    };
  };

  config = mkIf config.my.window-manager.enable {
    home.packages = [
      screenRecord
      screenshot
    ];

    # grim and wf-recorder don't create missing folders
    systemd.user.tmpfiles.rules = [
      "d ${screenshotDir} - - - -"
      "d ${recordingDir} - - - -"
    ];

    my.window-manager.keybinds = {
      ## Applications
      "Mod+Return".spawn = [ config.my.terminal.command ];
      "Mod+Shift+Q" = {
        hyprland = "killactive,";
        niri.close-window = { };
        sway = "kill";
        i3 = "kill";
      };

      # Lock directly (Mod+Ctrl+X goes through power-control)
      "Mod+Shift+X" = {
        hyprland = if cfg.hyprland.lockscreen.enable then "exec, ${pkgs.hyprlock}/bin/hyprlock" else null;
        niri =
          if cfg.niri.lockscreen.enable then
            {
              spawn = [
                "${pkgs.swaylock-effects}/bin/swaylock"
                "-f"
              ];
            }
          else
            null;
        sway = if cfg.sway.lockscreen.enable then "exec ${pkgs.swaylock-effects}/bin/swaylock -f" else null;
        i3 = "exec sh -c '${pkgs.i3lock-fancy-rapid}/bin/i3lock-fancy-rapid 15 8'";
      };

      ## Screenshots and recording
      "Mod+Shift+P" = {
        hyprland = "exec, ${screenshot}/bin/screenshot region";
        niri.screenshot = { };
        sway = "exec ${screenshot}/bin/screenshot region";
        i3 = "exec sh -c '${pkgs.maim}/bin/maim -s | ${pkgs.xclip}/bin/xclip -selection clipboard -t image/png'";
      };
      "Mod+Ctrl+P" = {
        hyprland = "exec, ${screenshot}/bin/screenshot output";
        niri.screenshot-screen = { };
        sway = "exec ${screenshot}/bin/screenshot output";
      };
      "Mod+V" = {
        hyprland = "exec, ${screenRecord}/bin/screen-record region";
        niri.spawn = [
          "${screenRecord}/bin/screen-record"
          "region"
        ];
        sway = "exec ${screenRecord}/bin/screen-record region";
      };
      "Mod+Shift+V" = {
        hyprland = "exec, ${screenRecord}/bin/screen-record output";
        niri.spawn = [
          "${screenRecord}/bin/screen-record"
          "output"
        ];
        sway = "exec ${screenRecord}/bin/screen-record output";
      };

      ## Notifiers
      "Mod+B".spawn = [ "battery-notifier" ];
      "Mod+Space".spawn = [ "system-notifier" ];
      "Mod+W".spawn = [ "workspace-notifier" ];
      "Mod+T".spawn = [ "time-notifier" ];

      ## Power
      "Mod+Escape".spawn = [
        "power-control"
        "menu"
      ];
      "Mod+Shift+Escape".spawn = [
        "power-control"
        "status"
      ];
      "Mod+Ctrl+X".spawn = [
        "power-control"
        "lock"
      ];
      "Mod+Ctrl+S".spawn = [
        "power-control"
        "suspend"
      ];

      ## Media, volume, brightness
      "XF86AudioPlay".spawn = [
        "media-player"
        "play"
      ];
      "Mod+S".spawn = [
        "media-player"
        "play"
      ];
      "XF86AudioNext".spawn = [
        "media-player"
        "next"
      ];
      "Mod+N".spawn = [
        "media-player"
        "next"
      ];
      "XF86AudioPrev".spawn = [
        "media-player"
        "previous"
      ];
      "Mod+P".spawn = [
        "media-player"
        "previous"
      ];
      "XF86AudioRaiseVolume" = {
        spawn = [
          "volume-control"
          "-i"
          "2"
        ];
        repeat = true;
      };
      "XF86AudioLowerVolume" = {
        spawn = [
          "volume-control"
          "-d"
          "2"
        ];
        repeat = true;
      };
      "XF86AudioMute" = {
        spawn = [
          "volume-control"
          "-m"
        ];
        repeat = true;
      };
      "XF86MonBrightnessUp" = {
        spawn = [
          "brightness-control"
          "-i"
          "10"
        ];
        repeat = true;
      };
      "XF86MonBrightnessDown" = {
        spawn = [
          "brightness-control"
          "-d"
          "10"
        ];
        repeat = true;
      };

      ## Launcher menus
      "Mod+O".spawn = launch "show" { mode = "desktopapplications"; };
      "Mod+D".spawn = launch "show" { mode = "websearch"; };
      "Mod+E".spawn = launch "show" { mode = "symbols"; };
      "Mod+C".spawn = launch "show" { mode = "clipboard"; };
      "Mod+U".spawn = launch "wifi" { };
      "Mod+Z".spawn = launch "bluetooth" { };
      "Mod+M".spawn = launch "monitor" { };
      "Mod+A".spawn = launch "audioOutput" { };
      "Mod+Shift+A".spawn = launch "audioInput" { };

      ## Layout: left/right walks columns, up/down walks workspaces, Ctrl acts
      ## within a column (niri's model; Hyprland's scrolling layout mimics it)
      "Mod+H" = {
        hyprland = "movefocus, l";
        niri.focus-column-left = { };
        sway = "focus left";
        i3 = "focus left";
      };
      "Mod+L" = {
        hyprland = "movefocus, r";
        niri.focus-column-right = { };
        sway = "focus right";
        i3 = "focus right";
      };
      "Mod+K" = {
        # Hyprland's `workspace m-1` wraps; the helper stops at the ends
        hyprland = "exec, hypr-workspace-step workspace -1";
        niri.focus-workspace-up = { };
        sway = "focus up";
        i3 = "focus up";
      };
      "Mod+J" = {
        hyprland = "exec, hypr-workspace-step workspace +1";
        niri.focus-workspace-down = { };
        sway = "focus down";
        i3 = "focus down";
      };
      "Mod+Shift+H" = {
        hyprland = "layoutmsg, swapcol l";
        niri.move-column-left = { };
        sway = "move left";
        i3 = "move left";
      };
      "Mod+Shift+L" = {
        hyprland = "layoutmsg, swapcol r";
        niri.move-column-right = { };
        sway = "move right";
        i3 = "move right";
      };
      "Mod+Shift+K" = {
        # Hyprland can only take the focused window along, not the column
        hyprland = "exec, hypr-workspace-step movetoworkspace -1";
        niri.move-column-to-workspace-up = { };
        sway = "move up";
        i3 = "move up";
      };
      "Mod+Shift+J" = {
        hyprland = "exec, hypr-workspace-step movetoworkspace +1";
        niri.move-column-to-workspace-down = { };
        sway = "move down";
        i3 = "move down";
      };
      "Mod+Ctrl+K" = {
        hyprland = "movefocus, u";
        niri.focus-window-up = { };
      };
      "Mod+Ctrl+J" = {
        hyprland = "movefocus, d";
        niri.focus-window-down = { };
      };
      "Mod+Ctrl+Shift+K" = {
        hyprland = "movewindow, u";
        niri.move-window-up = { };
      };
      "Mod+Ctrl+Shift+J" = {
        hyprland = "movewindow, d";
        niri.move-window-down = { };
      };
      "Mod+Ctrl+H" = {
        hyprland = "focusmonitor, l";
        niri.focus-monitor-left = { };
        sway = "focus output left";
        i3 = "focus output left";
      };
      "Mod+Ctrl+L" = {
        hyprland = "focusmonitor, r";
        niri.focus-monitor-right = { };
        sway = "focus output right";
        i3 = "focus output right";
      };
      "Mod+Ctrl+Shift+H" = {
        hyprland = "movewindow, mon:l";
        niri.move-column-to-monitor-left = { };
        sway = "move container to output left";
        i3 = "move container to output left";
      };
      "Mod+Ctrl+Shift+L" = {
        hyprland = "movewindow, mon:r";
        niri.move-column-to-monitor-right = { };
        sway = "move container to output right";
        i3 = "move container to output right";
      };
      "Mod+Comma" = {
        hyprland = "layoutmsg, consume";
        niri.consume-window-into-column = { };
      };
      "Mod+Period" = {
        hyprland = "layoutmsg, expel";
        niri.expel-window-from-column = { };
      };
      "Mod+Minus" = {
        hyprland = "layoutmsg, colresize -0.1";
        niri.set-column-width = "-10%";
        sway = "resize shrink width 10 ppt";
        i3 = "resize shrink width 10 ppt";
      };
      "Mod+Equal" = {
        hyprland = "layoutmsg, colresize +0.1";
        niri.set-column-width = "+10%";
        sway = "resize grow width 10 ppt";
        i3 = "resize grow width 10 ppt";
      };
      "Mod+Shift+Minus" = {
        hyprland = "resizeactive, 0 -10%";
        niri.set-window-height = "-10%";
        sway = "resize shrink height 10 ppt";
        i3 = "resize shrink height 10 ppt";
      };
      "Mod+Shift+Equal" = {
        hyprland = "resizeactive, 0 10%";
        niri.set-window-height = "+10%";
        sway = "resize grow height 10 ppt";
        i3 = "resize grow height 10 ppt";
      };
      "Mod+F" = {
        # Full column width <-> 0.5, staying tiled
        hyprland = "exec, hypr-toggle-column-maximize";
        niri.maximize-column = { };
      };
      "Mod+Shift+F" = {
        hyprland = "fullscreen";
        niri.fullscreen-window = { };
        sway = "fullscreen toggle";
        i3 = "fullscreen toggle";
      };

      ## Compositor-specific extras
      "Mod+R".hyprland = "layoutmsg, colresize +conf"; # cycle preset widths
      "Mod+Ctrl+C".hyprland = "layoutmsg, center";
      "Mod+Shift+B" = {
        hyprland = "exec, ${pkgs.hyprland}/bin/hyprctl keyword input:kb_variant"; # QWERTY
        niri.spawn = [
          "sh"
          "-c"
          "niri msg action switch-keyboard-layout"
        ];
      };
      "Mod+Shift+C".hyprland = "exec, ${pkgs.hyprland}/bin/hyprctl keyword input:kb_variant colemak";
      "Mod+Tab".niri.toggle-overview = { };
      "Mod+Shift+E".niri.quit.skip-confirmation = false;
    }
    // listToAttrs (
      concatMap (w: [
        (nameValuePair "Mod+${w.key}" {
          hyprland = "workspace, ${toString w.n}";
          niri.focus-workspace = w.n;
          sway = "workspace number ${toString w.n}";
          i3 = "workspace number ${toString w.n}";
        })
        (nameValuePair "Mod+Shift+${w.key}" {
          hyprland = "movetoworkspacesilent, ${toString w.n}";
          niri.move-column-to-workspace = w.n;
          sway = "move container to workspace number ${toString w.n}";
          i3 = "move container to workspace number ${toString w.n}";
        })
      ]) workspaceKeys
    );

    # Every backend's binds use these; each reads the backend itself
    my.launcher.enable = mkDefault true;
    my.controls.enable = mkDefault true;
    my.notifications.enable = mkDefault true;

    # Automatically enable the selected window manager
    my.window-manager.hyprland.enable = mkIf (config.my.window-manager.backend == "hyprland") (
      mkDefault true
    );
    my.window-manager.i3.enable = mkIf (config.my.window-manager.backend == "i3") (mkDefault true);
    my.window-manager.niri.enable = mkIf (config.my.window-manager.backend == "niri") (mkDefault true);
    my.window-manager.sway.enable = mkIf (config.my.window-manager.backend == "sway") (mkDefault true);

    # Custom compose sequences for special characters (works across all window managers)
    home.file.".XCompose".text = ''
      include "%L"

      # Swedish characters using Multi_key (Compose key)
      <Multi_key> <o> <o> : "ö"
      <Multi_key> <O> <O> : "Ö"
      <Multi_key> <e> <e> : "ä"
      <Multi_key> <E> <E> : "Ä"
      <Multi_key> <a> <a> : "å"
      <Multi_key> <A> <A> : "Å"
    '';

    # Environment variables for XIM to make .XCompose work in XWayland apps
    home.sessionVariables = {
      GTK_IM_MODULE = "xim"; # GTK apps (e.g., Slack) read .XCompose
      QT_IM_MODULE = "xim"; # Qt apps read .XCompose
      XMODIFIERS = "@im=none"; # Disable other input method frameworks
    };
  };
}
