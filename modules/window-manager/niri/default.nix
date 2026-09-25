{
  config,
  lib,
  pkgs,
  ...
}:
with lib;

let
  cfg = config.my.window-manager.niri;

  wmLib = import ../lib.nix { inherit lib; };

  # my.window-manager.monitors as niri outputs
  monitorOutputs = mapAttrs (
    _: m:
    {
      scale = wmLib.toFloat m.scale;
    }
    // optionalAttrs (!m.enable) { enable = false; }
    // optionalAttrs m.vrr { variable-refresh-rate = true; }
    // optionalAttrs (m.mode != null) {
      mode = {
        inherit (m.mode) width height;
      }
      // optionalAttrs (m.mode.refresh != null) { refresh = wmLib.toFloat m.mode.refresh; };
    }
    // optionalAttrs (m.position != null) { position = { inherit (m.position) x y; }; }
  ) config.my.window-manager.monitors;

in
{
  options.my.window-manager.niri = {
    enable = mkEnableOption "Enable Niri scrollable-tiling compositor";
    lockscreen.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable swaylock lock screen";
    };
  };

  config = mkIf cfg.enable {
    # home.pointerCursor is provided by stylix (stylix.cursor in the theming
    # module), including the x11/gtk integration the old block lacked.
    home = {
      packages =
        with pkgs;
        [
          grim
          slurp
          wl-clipboard
          systemd
          swaybg
          xwayland-satellite
        ]
        ++ optionals cfg.lockscreen.enable [
          swaylock-effects
        ];
    };

    # Idle management using swayidle
    services.swayidle = {
      enable = true;
      systemdTargets = [ "graphical-session.target" ];
      timeouts = [
        {
          timeout = config.my.window-manager.idle.dimAfter;
          command = "${pkgs.brightnessctl}/bin/brightnessctl -s set 10";
          resumeCommand = "${pkgs.brightnessctl}/bin/brightnessctl -r";
        }
      ]
      ++ (
        if cfg.lockscreen.enable then
          [
            {
              timeout = config.my.window-manager.idle.lockAfter;
              command = "${pkgs.systemd}/bin/loginctl lock-session";
            }
          ]
        else
          [ ]
      )
      ++ [
        {
          timeout = config.my.window-manager.idle.screenOffAfter;
          command = "niri msg action power-off-monitors";
          resumeCommand = "niri msg action power-on-monitors";
        }
        {
          timeout = config.my.window-manager.idle.suspendAfter;
          command = "${pkgs.systemd}/bin/systemctl suspend";
        }
      ];
      events =
        if cfg.lockscreen.enable then
          {
            "before-sleep" = "${pkgs.systemd}/bin/loginctl lock-session";
            "lock" = "${pkgs.swaylock-effects}/bin/swaylock -f";
          }
        else
          { };
    };

    # Wallpaper and colors come from stylix; only swaylock-effects extras
    # (blur, clock, indicator) are configured here.
    stylix.targets.swaylock.enable = cfg.lockscreen.enable;
    programs.swaylock = mkIf cfg.lockscreen.enable {
      enable = true;
      package = pkgs.swaylock-effects;
      settings = {
        # Background blur (like hyprlock blur_passes=2, blur_size=4)
        effect-blur = "7x5";
        effect-vignette = "0.5:0.5";

        # Clock display (like hyprlock's time label)
        clock = true;
        timestr = "%H:%M";
        datestr = "";

        # Indicator styling to match hyprlock input-field look
        indicator = true;
        indicator-radius = 100;
        indicator-thickness = 7;

        # Font settings
        font = config.my.theming.font.name;
        font-size = 24;

        # Behavior (matching hyprlock's no_fade_in/out)
        fade-in = 0;
        grace = 0;
        show-failed-attempts = true;
      };
    };

    # Workaround: xdg-desktop-portal-gnome gets D-Bus-activated before niri
    # exports org.gnome.Mutter.ScreenCast, leaving the portal stuck with no
    # screencast impl for the whole session. Wait for the interface, then
    # kick the portal so screen sharing works without manual intervention.
    systemd.user.services.niri-portal-fix = {
      Unit = {
        Description = "Restart xdg-desktop-portal once niri's ScreenCast is ready";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "niri-portal-fix" ''
          for _ in $(seq 1 50); do
            if ${pkgs.systemd}/bin/busctl --user list \
                | ${pkgs.gnugrep}/bin/grep -q org.gnome.Mutter.ScreenCast; then
              break
            fi
            sleep 0.2
          done
          ${pkgs.systemd}/bin/systemctl --user restart \
            xdg-desktop-portal-gnome.service xdg-desktop-portal.service
        '';
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };

    # Niri window manager configuration
    programs.niri = {
      enable = true;
      package = pkgs.niri-stable;
      settings = {
        # Fully dynamic workspaces (no named workspaces)

        # Prefer server-side decorations
        prefer-no-csd = true;

        # Screenshot path
        screenshot-path = "~/media/images/%Y-%m-%d_%H-%M-%S.png";

        # Input configuration
        input = {
          focus-follows-mouse = {
            enable = true;
            max-scroll-amount = "0%";
          };

          keyboard = {
            xkb = {
              layout = "us";
              variant = "colemak";
              options = "caps:escape,compose:${config.my.window-manager.composeKey}";
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
          touch = optionalAttrs (config.my.window-manager.touchOutput != null) {
            map-to-output = config.my.window-manager.touchOutput;
          };
        };

        # Output/monitor configuration
        outputs = monitorOutputs;

        # Layout configuration
        layout = {
          gaps = 6;
          center-focused-column = "never";
          # Always keep an empty workspace above the first one, allowing windows to be moved up
          empty-workspace-above-first = true;

          preset-column-widths = [
            { proportion = 1.0 / 3.0; }
            { proportion = 1.0 / 2.0; }
            { proportion = 2.0 / 3.0; }
          ];

          default-column-width = {
            proportion = 1.0 / 2.0;
          };

          focus-ring = {
            enable = true;
            width = 2;
            active.color = config.my.theming.colors.primary.foreground;
            inactive.color = config.my.theming.colors.primary.background;
          };

          border = {
            enable = false;
          };
        };

        # Spawn at startup
        # Note: Services like vicinae and dunst use systemd (graphical-session.target) instead
        spawn-at-startup = [
          # Wallpaper
          {
            command = [
              "${pkgs.swaybg}/bin/swaybg"
              "-i"
              "${config.my.theming.wallpaper}"
              "-m"
              "fill"
            ];
          }
        ]
        # Autostart applications
        ++ builtins.concatLists (
          builtins.attrValues (
            builtins.mapAttrs (
              name: app:
              if app == null then
                [ ]
              else
                [
                  {
                    command = [
                      "sh"
                      "-c"
                      app.command
                    ];
                  }
                ]
            ) config.my.window-manager.autostartApps
          )
        );

        # Cursor configuration
        cursor = {
          theme = config.my.theming.cursor.name;
          size = config.my.theming.cursor.size;
        };

        # Hotkey inhibitor (for nested compositors, games, etc.)
        hotkey-overlay.skip-at-startup = true;

        # Disable hot corner for overview
        gestures.hot-corners.enable = false;

        # Window rules
        window-rules = [
          # Round corners on all windows
          {
            geometry-corner-radius =
              let
                r = config.my.theming.cornerRadius * 1.0;
              in
              {
                top-left = r;
                top-right = r;
                bottom-left = r;
                bottom-right = r;
              };
            clip-to-geometry = true;
          }
          # Browsers -> workspace 1
          {
            matches = [
              { app-id = "^firefox$"; }
              { app-id = "^chromium-browser$"; }
              { app-id = "^google-chrome$"; }
              { app-id = "^zen$"; }
              { app-id = "^zen-browser$"; }
              { app-id = "^brave-browser$"; }
            ];
            open-on-workspace = "1";
            open-maximized = true;
          }
          # Chat apps -> workspace 2
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
            open-on-workspace = "2";
            open-maximized = true;
          }
        ];

        # The shared keymap (my.window-manager.keybinds)
        binds = concatMapAttrs (
          chord: e:
          let
            how = wmLib.entryFor "niri" e;
          in
          optionalAttrs (how != null) {
            ${chord}.action =
              if how ? spawn then
                {
                  spawn =
                    if isList how.spawn then
                      how.spawn
                    else
                      [
                        "sh"
                        "-c"
                        how.spawn
                      ];
                }
              else
                how.native;
          }
        ) config.my.window-manager.keybinds;

        # Animations
        animations = {
          # Enable animations
          slowdown = 1.0;
        };

        # Environment variables
        environment = {
          XDG_CURRENT_DESKTOP = "gnome"; # Tell portals to use GNOME backend for screen sharing
        };
      };
    };
  };
}
