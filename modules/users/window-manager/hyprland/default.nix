{ config, lib, pkgs, ... }:
with lib;

{
  options.hyprland = {
    enable = mkEnableOption "Enable Hyprland";
    lockscreen.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable lockscreen functionality (hyprlock, idle lock, etc.)";
    };
  };

  config = mkIf config.hyprland.enable {
    # Auto-enable notifications when hyprland is enabled (for util notifiers)
    notifications.enable = mkDefault true;

    # Auto-enable launcher when hyprland is enabled
    launcher.enable = mkDefault true;
    # Auto-enable controls when hyprland is enabled
    controls.enable = mkDefault true;
    controls.windowManager = "hyprland";

    # Multi-gestures
    # services.touchegg.enable = true;  # TODO: Move to system level

    home = {
      pointerCursor = {
        inherit (config.theme.cursor) name package;
        hyprcursor = {
          enable = true;
          inherit (config.theme.cursor) size;
        };
      };
      packages = with pkgs; [ hyprlock grim slurp wl-clipboard systemd ];
    };

    services.hyprpaper = {
      enable = true;
      settings = {
        preload = "${config.theme.wallpaper}";
        wallpaper = ",${config.theme.wallpaper}";
        splash = false;
      };
    };

    services.hypridle = {
      enable = true;
      settings = {
        general = {
          after_sleep_cmd = "${pkgs.hyprland}/bin/hyprctl dispatch dpms on";
          ignore_dbus_inhibit = false;
        } // (if config.hyprland.lockscreen.enable then {
          lock_cmd =
            "${pkgs.procps}/bin/pgrep -x hyprlock || ${pkgs.hyprlock}/bin/hyprlock";
          before_sleep_cmd = "${pkgs.systemd}/bin/loginctl lock-session";
        } else {});

        listener = [
          {
            timeout = 240; # 4 minutes
            on-timeout = "${pkgs.brightnessctl}/bin/brightnessctl -s set 10";
            on-resume = "${pkgs.brightnessctl}/bin/brightnessctl -r";
          }
        ] ++ (if config.hyprland.lockscreen.enable then [
          {
            timeout = 300; # 5 minutes
            on-timeout = "${pkgs.systemd}/bin/loginctl lock-session";
          }
        ] else []) ++ [
          {
            timeout = 330; # 5.5 minutes
            on-timeout = "${pkgs.hyprland}/bin/hyprctl dispatch dpms off";
            on-resume = "${pkgs.hyprland}/bin/hyprctl dispatch dpms on";
          }
          {
            timeout = 900; # 15 minutes
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

    programs.hyprlock = mkIf config.hyprland.lockscreen.enable {
      enable = true;
      settings = {
        general = {
          hide_cursor = true;
          grace = 0;
          no_fade_out = true;
          no_fade_in = true;
        };

        auth = {
          fingerprint = {
            enabled = true;
            ready_message = "Scan fingerprint to unlock";
            present_message = "Scanning...";
          };
        };

        background = [{
          path = "${config.theme.wallpaper}";
          blur_passes = 2;
          blur_size = 4;
        }];

        input-field = [{
          size = "300, 50";
          outline_thickness = 2;
          dots_size = 0.2;
          dots_spacing = 0.5;
          outer_color = "rgb(${lib.strings.removePrefix "#" config.theme.colors.primary.foreground})";
          inner_color = "rgb(${lib.strings.removePrefix "#" config.theme.colors.primary.background})";
          font_color = "rgb(${lib.strings.removePrefix "#" config.theme.colors.primary.foreground})";
          fade_on_empty = false;
          placeholder_text = "<i>$FPRINTPROMPT</i>";
          hide_input = false;
          position = "0, -50";
          halign = "center";
          valign = "center";
        }];

        label = [{
          text = "$TIME";
          color = "rgb(${lib.strings.removePrefix "#" config.theme.colors.primary.foreground})";
          font_size = 64;
          font_family = "monospace";
          position = "0, 150";
          halign = "center";
          valign = "center";
        }];
      };
    };

    wayland.windowManager.hyprland = {
      enable = true;
      systemd.variables = [ "--all" ];
      settings = {
        monitor = config.windowManager.monitors;

        # Workspace to monitor bindings
        workspace = map (wb:
          "${toString wb.workspace}, monitor:${wb.monitor}"
          + (if wb.default then ", default:true" else "")
        ) config.windowManager.workspaceBindings;

        cursor = { enable_hyprcursor = false; };

        "$mod" = "SUPER";
        "$modShift" = "SUPER_SHIFT";
        "$modCtrl" = "SUPER_CTRL";

        exec-once = [
          # Launcher daemons (walker, vicinae) are started via systemd services
        ]
          # Create persistent virtual/headless monitors at startup
          # Then restart Sunshine so it detects them (required for headless streaming)
          ++ (if config.windowManager.virtualMonitors != [] then
            (map (name:
              "${pkgs.hyprland}/bin/hyprctl output create headless ${name}"
            ) config.windowManager.virtualMonitors)
            ++ [ "sleep 2 && ${pkgs.systemd}/bin/systemctl --user restart sunshine || true" ]
          else [])
          # Autostart applications
          ++ builtins.concatLists (builtins.attrValues (builtins.mapAttrs
            (name: app:
              if app == null then
                [ ]
              else
                let
                  # Autostart applications on provided worspace
                  workspacePrefix = if app.workspace != null then
                    "[workspace ${toString app.workspace}] "
                  else
                    "";
                in [ "${workspacePrefix}${app.command}" ])
            config.windowManager.autostartApps));

        general = {
          "col.active_border" = "rgb(${
              lib.strings.removePrefix "#"
              config.theme.colors.primary.foreground
            })";
        };

        dwindle = { force_split = 2; };

        decoration = { rounding = 5; };

        bind = [
          ### Keyboard layouts
          # Qwerty
          "$modShift, b, exec, ${pkgs.hyprland}/bin/hyprctl keyword input:kb_variant"

          # Colemak
          "$modShift, c, exec, ${pkgs.hyprland}/bin/hyprctl keyword input:kb_variant colemak"

          ### Applications
          # Terminal
          "$mod, RETURN, exec, ${pkgs.alacritty}/bin/alacritty"
        ] ++ (lib.optionals config.hyprland.lockscreen.enable [
          # Lock screen
          "$modShift, x, exec, ${pkgs.hyprlock}/bin/hyprlock"
        ]) ++ [

          # Print screen
          ''
            $modShift, p, exec, ${pkgs.grim}/bin/grim -g "$(${pkgs.slurp}/bin/slurp)" ~/media/images/$(${pkgs.coreutils}/bin/date -Iseconds).png''

          # Record screen (toggle: press to start, press again to stop)
          # Records the currently focused monitor using H.264 in MKV container (more resilient)
          ''
            $mod, v, exec, ${pkgs.procps}/bin/pkill -SIGINT wf-recorder && ${
              config.notifications.send {
                summary = "Recording Stopped";
                icon = "media-playback-stop";
                appName = "Screen Recorder";
              }
            } || { ${
              config.notifications.send {
                summary = "Recording Started";
                icon = "media-record";
                appName = "Screen Recorder";
              }
            }; ${pkgs.wf-recorder}/bin/wf-recorder -o "$(${pkgs.hyprland}/bin/hyprctl monitors -j | ${pkgs.jq}/bin/jq -r '.[] | select(.focused) | .name')" -c libx264 -p crf=23 -p preset=fast --pixel-format yuv420p -f ~/media/videos/$(${pkgs.coreutils}/bin/date -Iseconds).mkv; }''

          ### Screen handling
          # Forcus navigation
          "$mod, h, movefocus, l"
          "$mod, l, movefocus, r"
          "$mod, k, movefocus, u"
          "$mod, j, movefocus, d"

          # Move application in screen
          "$modShift, h, movewindow, l"
          "$modShift, l, movewindow, r"
          "$modShift, k, movewindow, u"
          "$modShift, j, movewindow, d"

          # Fullscreen application
          "$mod, f, fullscreen"

          # Kill application
          "$modShift, q, killactive,"

          ### Notifiers

          # Battery status
          "$mod, b, exec, battery-notifier"

          # System resources, e.g. cpu, mem, storage
          "$mod, SPACE, exec, system-notifier"

          # Workspace information
          "$mod, w, exec, workspace-notifier"

          # Clock
          "$mod, t, exec, time-notifier"

          ### Power Management
          # Power menu
          "$mod, Escape, exec, power-control menu"

          # Quick lock
          "$modCtrl, l, exec, power-control lock"

          # Quick suspend
          "$modCtrl, s, exec, power-control suspend"

          # Power status
          "$modShift, Escape, exec, power-control status"

          ### Control
          # Media
          ", XF86AudioPlay, exec, media-player play"
          "$mod, s, exec, media-player play"
          ", XF86AudioNext, exec, media-player next"
          "$mod, n, exec, media-player next"
          ", XF86AudioPrev, exec, media-player previous"
          "$mod, p, exec, media-player previous"
        ] ++ (lib.optionals config.launcher.enable [
          ### Launchers
          # Emojis
          "$mod, e, exec, ${config.launcher.show { mode = "symbols"; }}"

          # Wifi
          "$mod, u, exec, ${config.launcher.wifi { }}"

          # Bluetooth
          "$mod, z, exec, ${config.launcher.bluetooth { }}"

          # Monitors
          "$mod, m, exec, ${config.launcher.monitor { }}"

          # Websearch
          "$mod, d, exec, ${config.launcher.show { mode = "websearch"; }}"

          # Applications
          "$mod, o, exec, ${
            config.launcher.show { mode = "desktopapplications"; }
          }"
          # Clipboard
          "$mod, c, exec, ${config.launcher.show { mode = "clipboard"; }}"

          # Audio sink/source launchers
          "$mod, a, exec, ${config.launcher.audioOutput { }}"
          "$modShift, a, exec, ${config.launcher.audioInput { }}"
        ]) ++ (builtins.concatLists (builtins.genList (x:
          let
            ws = let c = (x + 1) / 10; in builtins.toString (x + 1 - (c * 10));
          in [
            # Move focus to workspace x
            "$mod, ${ws}, workspace, ${toString (x + 1)}"
            # Move focused application to workspace x
            "$modShift, ${ws}, movetoworkspacesilent, ${toString (x + 1)}"
          ]) 10));
        binds = { movefocus_cycles_fullscreen = true; };
        binde = [
          ### Controls
          # Brightness
          ", XF86MonBrightnessUp,  exec, brightness-control -i 10"
          ", XF86MonBrightnessDown, exec, brightness-control -d 10"

          # Volume
          ", XF86AudioRaiseVolume, exec, volume-control -i 2"
          ", XF86AudioLowerVolume, exec, volume-control -d 2"
          ", XF86AudioMute, exec, volume-control -m"
        ];

        # Lid switch bindings for lock and display power management
        bindl = lib.optionals config.hyprland.lockscreen.enable [
          # Lock screen when lid closes
          ", switch:on:Lid Switch, exec, ${pkgs.procps}/bin/pgrep -x hyprlock || ${pkgs.hyprlock}/bin/hyprlock"
          # Turn off display when lid closes (power saving while locked)
          ", switch:on:Lid Switch, exec, ${pkgs.hyprland}/bin/hyprctl dispatch dpms off"
          # Turn display back on when lid opens
          ", switch:off:Lid Switch, exec, ${pkgs.hyprland}/bin/hyprctl dispatch dpms on"
        ];

        misc = {
          disable_splash_rendering = true;
          vfr = true;
        };

        debug = {
          enable_stdout_logs = true;
          disable_logs = false;
        };

        gestures = { };

        input = {
          kb_layout = "us";
          kb_variant = "colemak";
          kb_options = "caps:escape,compose:${config.windowManager.composeKey}";
          resolve_binds_by_sym = 1;

          touchpad = {
            natural_scroll = false;
            disable_while_typing = true;
            scroll_factor = 1.0;
          };

          sensitivity = 0;
          accel_profile = "flat";
        } // optionalAttrs (config.windowManager.touchOutput != null) {
          touchdevice = { output = config.windowManager.touchOutput; };
        };
      };
    };
  };
}
