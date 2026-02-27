{ config, lib, pkgs, ... }:
with lib;

let
  cfg = config.niri;

  # Convert Hyprland monitor format to Niri output format
  # Hyprland: "name,resolution@refresh,position,scale"
  # Niri: outputs."name" = { mode = { width = W; height = H; refresh = R; }; scale = S; }
  parseMonitor = monitorStr:
    let
      parts = lib.splitString "," monitorStr;
      name = builtins.elemAt parts 0;
      resolution = builtins.elemAt parts 1;
      position = builtins.elemAt parts 2;
      scale = builtins.elemAt parts 3;

      # Parse resolution (e.g., "3440x1440@240" or "preferred")
      resolutionParsed =
        if resolution == "preferred" then null
        else
          let
            hasRefresh = lib.hasInfix "@" resolution;
            resParts = if hasRefresh then lib.splitString "@" resolution else [ resolution "60" ];
            dimParts = lib.splitString "x" (builtins.elemAt resParts 0);
          in {
            width = lib.toInt (builtins.elemAt dimParts 0);
            height = lib.toInt (builtins.elemAt dimParts 1);
            refresh = lib.toFloat (builtins.elemAt resParts 1);
          };

      # Parse position (e.g., "0x0" or "auto")
      positionParsed =
        if position == "auto" then null
        else
          let
            posParts = lib.splitString "x" position;
          in {
            x = lib.toInt (builtins.elemAt posParts 0);
            y = lib.toInt (builtins.elemAt posParts 1);
          };
    in {
      inherit name;
      mode = resolutionParsed;
      position = positionParsed;
      scale = lib.toFloat scale;
    };

  # Generate outputs configuration for Niri
  monitorOutputs = builtins.listToAttrs (
    builtins.filter (x: x.name != "") (
      map (monitorStr:
        let parsed = parseMonitor monitorStr;
        in {
          name = if parsed.name == "" then null else parsed.name;
          value = {
            scale = parsed.scale;
          } // optionalAttrs (parsed.mode != null) {
            mode = parsed.mode;
          } // optionalAttrs (parsed.position != null) {
            position = parsed.position;
          };
        }
      ) config.windowManager.monitors
    )
  );

  # Check if we have any named monitors
  hasNamedMonitors = builtins.any (m: (builtins.elemAt (lib.splitString "," m) 0) != "") config.windowManager.monitors;

in {
  options.niri = {
    enable = mkEnableOption "Enable Niri scrollable-tiling compositor";
    lockscreen.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable swaylock lock screen";
    };
  };

  config = mkIf cfg.enable {
    # Auto-enable notifications when niri is enabled
    notifications.enable = mkDefault true;
    notifications.windowManager = "niri";

    # Auto-enable launcher when niri is enabled
    launcher.enable = mkDefault true;
    launcher.windowManager = "niri";

    # Auto-enable controls when niri is enabled
    controls.enable = mkDefault true;
    controls.windowManager = "niri";

    home = {
      pointerCursor = {
        inherit (config.theme.cursor) name package;
      };
      packages = with pkgs; [
        grim
        slurp
        wl-clipboard
        systemd
        swaybg
        xwayland-satellite
      ] ++ optionals cfg.lockscreen.enable [
        swaylock
      ];
    };

    # Idle management using swayidle
    services.swayidle = {
      enable = true;
      systemdTarget = "graphical-session.target";
      timeouts = [
        {
          timeout = 240; # 4 minutes
          command = "${pkgs.brightnessctl}/bin/brightnessctl -s set 10";
          resumeCommand = "${pkgs.brightnessctl}/bin/brightnessctl -r";
        }
      ] ++ (if cfg.lockscreen.enable then [
        {
          timeout = 300; # 5 minutes
          command = "${pkgs.systemd}/bin/loginctl lock-session";
        }
      ] else []) ++ [
        {
          timeout = 330; # 5.5 minutes
          command = "niri msg action power-off-monitors";
          resumeCommand = "niri msg action power-on-monitors";
        }
        {
          timeout = 900; # 15 minutes
          command = "${pkgs.systemd}/bin/systemctl suspend";
        }
      ];
      events = if cfg.lockscreen.enable then [
        {
          event = "before-sleep";
          command = "${pkgs.systemd}/bin/loginctl lock-session";
        }
        {
          event = "lock";
          command = "${pkgs.swaylock}/bin/swaylock -f";
        }
      ] else [];
    };

    # Swaylock configuration
    programs.swaylock = mkIf cfg.lockscreen.enable {
      enable = true;
      settings = {
        image = "${config.theme.wallpaper}";
        scaling = "fill";
        color = lib.strings.removePrefix "#" config.theme.colors.primary.background;
        inside-color = lib.strings.removePrefix "#" config.theme.colors.primary.background;
        inside-clear-color = lib.strings.removePrefix "#" config.theme.colors.primary.background;
        inside-ver-color = lib.strings.removePrefix "#" config.theme.colors.primary.background;
        inside-wrong-color = lib.strings.removePrefix "#" config.theme.colors.primary.background;
        key-hl-color = lib.strings.removePrefix "#" config.theme.colors.primary.foreground;
        ring-color = lib.strings.removePrefix "#" config.theme.colors.primary.foreground;
        ring-clear-color = lib.strings.removePrefix "#" config.theme.colors.primary.foreground;
        ring-ver-color = lib.strings.removePrefix "#" config.theme.colors.primary.foreground;
        ring-wrong-color = "ff0000";
        line-color = "00000000";
        text-color = lib.strings.removePrefix "#" config.theme.colors.primary.foreground;
        font = config.theme.font.name;
        font-size = 24;
        indicator-radius = 100;
        indicator-thickness = 10;
        show-failed-attempts = true;
      };
    };

    # Niri window manager configuration
    programs.niri = {
      enable = true;
      package = pkgs.niri-stable;
      settings = {
        # Named workspaces (browser, chat, code - rest are dynamic)
        workspaces = {
          "browser" = {};
          "chat" = {};
          "code" = {};
        };

        # Prefer server-side decorations
        prefer-no-csd = true;

        # Screenshot path
        screenshot-path = "~/media/images/%Y-%m-%d_%H-%M-%S.png";

        # Input configuration
        input = {
          focus-follows-mouse.enable = true;

          keyboard = {
            xkb = {
              layout = "us";
              variant = "colemak";
              options = "caps:escape,compose:${config.windowManager.composeKey}";
            };
          };

          touchpad = {
            tap = true;
            natural-scroll = false;
            accel-profile = "flat";
          };

          mouse = {
            accel-profile = "flat";
          };

          # Map touchscreen to specific output if configured
          touch = optionalAttrs (config.windowManager.touchOutput != null) {
            map-to-output = config.windowManager.touchOutput;
          };
        };

        # Output/monitor configuration
        outputs = if hasNamedMonitors then monitorOutputs else {};

        # Layout configuration
        layout = {
          gaps = 6;
          center-focused-column = "never";

          preset-column-widths = [
            { proportion = 1.0 / 3.0; }
            { proportion = 1.0 / 2.0; }
            { proportion = 2.0 / 3.0; }
          ];

          default-column-width = { proportion = 1.0 / 2.0; };

          focus-ring = {
            enable = true;
            width = 2;
            active.color = config.theme.colors.primary.foreground;
            inactive.color = config.theme.colors.primary.background;
          };

          border = {
            enable = false;
          };
        };

        # Spawn at startup
        # Note: Services like vicinae and dunst use systemd (graphical-session.target) instead
        spawn-at-startup = [
          # Wallpaper
          { command = [ "${pkgs.swaybg}/bin/swaybg" "-i" "${config.theme.wallpaper}" "-m" "fill" ]; }
          # Start XWayland satellite for X11 app compatibility
          { command = [ "${pkgs.xwayland-satellite}/bin/xwayland-satellite" ]; }
        ]
        # Autostart applications
        ++ builtins.concatLists (builtins.attrValues (builtins.mapAttrs
          (name: app:
            if app == null then []
            else [{ command = [ "sh" "-c" app.command ]; }]
          ) config.windowManager.autostartApps));

        # Cursor configuration
        cursor = {
          theme = config.theme.cursor.name;
          size = config.theme.cursor.size;
        };

        # Hotkey inhibitor (for nested compositors, games, etc.)
        hotkey-overlay.skip-at-startup = true;

        # Window rules
        window-rules = [
          # Round corners on all windows
          {
            geometry-corner-radius = let r = 5.0; in { top-left = r; top-right = r; bottom-left = r; bottom-right = r; };
            clip-to-geometry = true;
          }
          # Browsers -> browser workspace
          {
            matches = [
              { app-id = "^firefox$"; }
              { app-id = "^chromium-browser$"; }
              { app-id = "^google-chrome$"; }
              { app-id = "^zen$"; }
              { app-id = "^zen-browser$"; }
              { app-id = "^brave-browser$"; }
            ];
            open-on-workspace = "browser";
            open-maximized = true;
          }
          # Chat apps -> chat workspace
          {
            matches = [
              { app-id = "^Slack$"; }
              { app-id = "^slack$"; }
              { app-id = "^discord$"; }
              { app-id = "^Discord$"; }
              { app-id = "^telegram-desktop$"; }
              { app-id = "^signal$"; }
              { app-id = "^Element$"; }
            ];
            open-on-workspace = "chat";
            open-maximized = true;
          }
        ];

        # Keybindings
        binds = {
          # Keyboard layout switching
          "Mod+Shift+B".action.spawn = [ "sh" "-c" "niri msg action switch-keyboard-layout" ];

          # Terminal
          "Mod+Return".action.spawn = [ config.terminal.command ];

          # Lock screen
          "Mod+Shift+X".action = if cfg.lockscreen.enable
            then { spawn = [ "${pkgs.swaylock}/bin/swaylock" "-f" ]; }
            else null;

          # Screenshot (region)
          "Mod+Shift+P".action.screenshot-screen = {};

          # Screenshot (window)
          "Mod+P".action.screenshot-window = {};

          # Screen recording toggle
          "Mod+V".action.spawn = [
            "sh" "-c"
            ''
              if ${pkgs.procps}/bin/pkill -SIGINT wf-recorder; then
                ${config.notifications.send {
                  summary = "Recording Stopped";
                  icon = "media-playback-stop";
                  appName = "Screen Recorder";
                }}
              else
                ${config.notifications.send {
                  summary = "Recording Started";
                  icon = "media-record";
                  appName = "Screen Recorder";
                }}
                ${pkgs.wf-recorder}/bin/wf-recorder -c libx264 -p crf=23 -p preset=fast --pixel-format yuv420p -f ~/media/videos/$(${pkgs.coreutils}/bin/date -Iseconds).mkv
              fi
            ''
          ];

          # Focus navigation (Niri uses columns horizontally, workspaces vertically)
          "Mod+H".action.focus-column-left = {};
          "Mod+L".action.focus-column-right = {};
          "Mod+K".action.focus-workspace-up = {};
          "Mod+J".action.focus-workspace-down = {};

          # Move column between workspaces
          "Mod+Shift+H".action.move-column-left = {};
          "Mod+Shift+L".action.move-column-right = {};
          "Mod+Shift+K".action.move-column-to-workspace-up = {};
          "Mod+Shift+J".action.move-column-to-workspace-down = {};

          # Focus window within column
          "Mod+Ctrl+K".action.focus-window-up = {};
          "Mod+Ctrl+J".action.focus-window-down = {};

          # Move window within column
          "Mod+Ctrl+Shift+K".action.move-window-up = {};
          "Mod+Ctrl+Shift+J".action.move-window-down = {};

          # Consume/expel windows into/from columns
          "Mod+Comma".action.consume-window-into-column = {};
          "Mod+Period".action.expel-window-from-column = {};

          # Column width adjustments
          "Mod+Minus".action.set-column-width = "-10%";
          "Mod+Equal".action.set-column-width = "+10%";

          # Window height adjustments
          "Mod+Shift+Minus".action.set-window-height = "-10%";
          "Mod+Shift+Equal".action.set-window-height = "+10%";

          # Maximize column (like fullscreen in traditional WMs)
          "Mod+F".action.maximize-column = {};

          # Fullscreen window
          "Mod+Shift+F".action.fullscreen-window = {};

          # Kill window
          "Mod+Shift+Q".action.close-window = {};

          # Notifiers
          "Mod+B".action.spawn = [ "battery-notifier" ];
          "Mod+Space".action.spawn = [ "system-notifier" ];
          "Mod+W".action.spawn = [ "workspace-notifier" ];
          "Mod+T".action.spawn = [ "time-notifier" ];

          # Power management
          "Mod+Escape".action.spawn = [ "power-control" "menu" ];
          "Mod+Ctrl+X".action.spawn = [ "power-control" "lock" ];
          "Mod+Ctrl+S".action.spawn = [ "power-control" "suspend" ];
          "Mod+Shift+Escape".action.spawn = [ "power-control" "status" ];

          # Media controls
          "XF86AudioPlay".action.spawn = [ "media-player" "play" ];
          "Mod+S".action.spawn = [ "media-player" "play" ];
          "XF86AudioNext".action.spawn = [ "media-player" "next" ];
          "Mod+N".action.spawn = [ "media-player" "next" ];
          "XF86AudioPrev".action.spawn = [ "media-player" "previous" ];
          # Note: Mod+P conflicts with screenshot, using Alt instead
          "Mod+Alt+P".action.spawn = [ "media-player" "previous" ];

          # Brightness controls (using allow-when-locked for these)
          "XF86MonBrightnessUp".action.spawn = [ "brightness-control" "-i" "10" ];
          "XF86MonBrightnessDown".action.spawn = [ "brightness-control" "-d" "10" ];

          # Volume controls
          "XF86AudioRaiseVolume".action.spawn = [ "volume-control" "-i" "2" ];
          "XF86AudioLowerVolume".action.spawn = [ "volume-control" "-d" "2" ];
          "XF86AudioMute".action.spawn = [ "volume-control" "-m" ];

          # Named workspace shortcuts
          "Mod+1".action.focus-workspace = "browser";
          "Mod+2".action.focus-workspace = "chat";
          "Mod+3".action.focus-workspace = "code";
          "Mod+Shift+1".action.move-column-to-workspace = "browser";
          "Mod+Shift+2".action.move-column-to-workspace = "chat";
          "Mod+Shift+3".action.move-column-to-workspace = "code";

          # Switch between monitors (H/L only, J/K used for window focus)
          "Mod+Ctrl+H".action.focus-monitor-left = {};
          "Mod+Ctrl+L".action.focus-monitor-right = {};

          # Move column to monitor (H/L only, J/K used for window movement)
          "Mod+Shift+Ctrl+H".action.move-column-to-monitor-left = {};
          "Mod+Shift+Ctrl+L".action.move-column-to-monitor-right = {};

          # Overview (Niri's built-in feature)
          "Mod+Tab".action.toggle-overview = {};

          # Quit Niri
          "Mod+Shift+E".action.quit = { skip-confirmation = false; };
        } // (if config.launcher.enable then {
          # Launcher bindings
          "Mod+E".action.spawn = [ "sh" "-c" (config.launcher.show { mode = "symbols"; }) ];
          "Mod+U".action.spawn = [ "sh" "-c" (config.launcher.wifi { }) ];
          "Mod+Z".action.spawn = [ "sh" "-c" (config.launcher.bluetooth { }) ];
          # Note: Monitor keybinding removed - uses Hyprland-specific extension
          "Mod+D".action.spawn = [ "sh" "-c" (config.launcher.show { mode = "websearch"; }) ];
          "Mod+O".action.spawn = [ "sh" "-c" (config.launcher.show { mode = "desktopapplications"; }) ];
          "Mod+C".action.spawn = [ "sh" "-c" (config.launcher.show { mode = "clipboard"; }) ];
          "Mod+A".action.spawn = [ "sh" "-c" (config.launcher.audioOutput { }) ];
          "Mod+Shift+A".action.spawn = [ "sh" "-c" (config.launcher.audioInput { }) ];
        } else {});

        # Animations
        animations = {
          # Enable animations
          slowdown = 1.0;
        };

        # Environment variables
        environment = {
          DISPLAY = ":0"; # For xwayland-satellite
          XDG_CURRENT_DESKTOP = "gnome"; # Tell portals to use GNOME backend for screen sharing
        };
      };
    };
  };
}
