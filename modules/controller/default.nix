{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

{
  options.controller = {
    enable = mkEnableOption "Enable controller support and custom mappings";

    type = mkOption {
      type = types.enum [
        "ps5"
        "xbox"
        "generic"
      ];
      default = "ps5";
      description = "Type of controller to configure";
    };

    mangohudToggle = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable MangoHud toggle via controller buttons";
      };

      buttons = mkOption {
        type = types.listOf (
          types.enum [
            "square"
            "triangle"
            "circle"
            "x"
            "share"
            "options"
            "l3"
            "r3"
          ]
        );
        default = [
          "square"
          "triangle"
        ];
        description = "Controller buttons that trigger MangoHud toggle";
      };

      autoStart = mkOption {
        type = types.bool;
        default = true;
        description = "Automatically start controller monitoring service";
      };
    };

    customMappings = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable custom controller button mappings";
      };

      mappings = mkOption {
        type = types.attrsOf types.str;
        default = { };
        example = {
          "l3+r3" = "screenshot";
          "share+options" = "record";
        };
        description = "Custom button combination to command mappings";
      };
    };

    steamOverlay = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Open the Steam overlay from the streamed gamepad by injecting its
          keyboard shortcut (Shift+Tab) on a button chord. Needed over Moonlight
          because Steam Input is off for the Sunshine virtual pad (so the pad's
          Guide button can't reach Steam), and there is no keyboard.
        '';
      };

      buttons = mkOption {
        type = types.listOf (
          types.enum [
            "a" "b" "x" "y" "l1" "r1" "l2" "r2" "select" "start" "guide" "l3" "r3"
          ]
        );
        default = [ "l3" "r3" ];
        description = "Chord (all buttons held together) that opens the Steam overlay";
      };

      holdSeconds = mkOption {
        type = types.float;
        default = 0.2;
        description = "How long the chord must be held so an accidental single click doesn't fire";
      };

      padName = mkOption {
        type = types.str;
        default = "Sunshine X-Box One (virtual) pad";
        description = "Name (in /proc/bus/input/devices) of the streamed gamepad to watch";
      };
    };

    rumble = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable controller rumble/haptic feedback";
      };
    };

    ledSettings = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable custom LED settings for supported controllers";
      };

      color = mkOption {
        type = types.str;
        default = "blue";
        description = "LED color for supported controllers";
      };

      brightness = mkOption {
        type = types.int;
        default = 128;
        description = "LED brightness (0-255)";
      };
    };
  };

  config = mkIf config.controller.enable {
    home.packages =
      with pkgs;
      [
        evtest
        coreutils
        inotify-tools
        wtype
        procps
      ]
      ++ optionals config.controller.customMappings.enable [
        # Add additional packages for custom mappings if needed
      ];

    # MangoHud toggle script
    home.file."bin/controller-mangohud-toggle.sh" = mkIf config.controller.mangohudToggle.enable {
      text =
        let
          controllerType = config.controller.type;
          buttons = config.controller.mangohudToggle.buttons;

          buttonMappings = {
            ps5 = {
              square = "BTN_WEST";
              triangle = "BTN_NORTH";
              circle = "BTN_EAST";
              x = "BTN_SOUTH";
              share = "BTN_SELECT";
              options = "BTN_START";
              l3 = "BTN_THUMBL";
              r3 = "BTN_THUMBR";
            };
            xbox = {
              x = "BTN_WEST";
              y = "BTN_NORTH";
              b = "BTN_EAST";
              a = "BTN_SOUTH";
              back = "BTN_SELECT";
              start = "BTN_START";
              l3 = "BTN_THUMBL";
              r3 = "BTN_THUMBR";
            };
            generic = {
              btn1 = "BTN_SOUTH";
              btn2 = "BTN_EAST";
              btn3 = "BTN_WEST";
              btn4 = "BTN_NORTH";
              select = "BTN_SELECT";
              start = "BTN_START";
              l3 = "BTN_THUMBL";
              r3 = "BTN_THUMBR";
            };
          };

          controllerNames = {
            ps5 = "DualSense Wireless Controller";
            xbox = "Xbox.*Controller";
            generic = ".*[Cc]ontroller.*";
          };

          generateButtonChecks =
            buttons:
            let
              currentMappings = buttonMappings.${controllerType};
              buttonChecks = map (btn: ''
                if echo "$line" | grep -q "${currentMappings.${btn}}.*value 1"; then
                        echo "${btn} button pressed - toggling MangoHud..."
                        toggle_mangohud
                        echo "MangoHud toggled with ${btn}!"
                        sleep 0.5  # Prevent rapid toggling
                    fi'') buttons;
            in
            concatStringsSep "\n        " buttonChecks;

        in
        ''
          #!${pkgs.bash}/bin/bash
          # Controller to MangoHud toggle script (Gamescope compatible)
          # Generated by NixOS controller module

          set -euo pipefail

          # Logging function
          log() {
              echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >&2
          }

          # MangoHud toggle function for gamescope
          toggle_mangohud() {
              # Method 1: Try to find and signal the gamescope process
              if pgrep -f "gamescope" >/dev/null; then
                  log "Found gamescope process, sending F12 to toggle MangoHud"
                  # Use gamescope's built-in MangoHud toggle (F12 by default)
                  if command -v wtype >/dev/null 2>&1; then
                      wtype -k F12
                  elif [ -e /dev/input/by-path/*kbd* ]; then
                      # Fallback: write directly to keyboard device
                      echo -ne '\e[24~' > /dev/tty 2>/dev/null || true
                  fi
              else
                  log "No gamescope process found, trying alternative methods"
                  # Method 2: Toggle via MangoHud control file if it exists
                  if [ -w "/tmp/mangohud_toggle" ]; then
                      echo "toggle" > /tmp/mangohud_toggle
                  elif [ -w "/run/user/$(id -u)/mangohud_toggle" ]; then
                      echo "toggle" > "/run/user/$(id -u)/mangohud_toggle"
                  else
                      log "WARNING: Could not toggle MangoHud - no gamescope or control file found"
                  fi
              fi
          }

          # Find controller device
          find_controller() {
              local controller_name="${controllerNames.${controllerType}}"
              log "Looking for controller: $controller_name"

              local controller_event
              controller_event=$(cat /proc/bus/input/devices 2>/dev/null | \
                  grep -B 5 -A 5 "$controller_name" | \
                  grep "Handlers" | \
                  grep -o "event[0-9]*" | \
                  head -1)

              if [ -n "$controller_event" ]; then
                  echo "/dev/input/$controller_event"
                  return 0
              fi
              return 1
          }

          # Monitor single controller
          monitor_controller() {
              local controller_path="$1"

              if [ ! -r "$controller_path" ]; then
                  log "ERROR: No read permission for $controller_path"
                  log "Current user: $(whoami), Groups: $(groups)"
                  log "Device permissions: $(ls -la "$controller_path" 2>/dev/null || echo "Device not found")"
                  return 1
              fi

              log "Successfully found ${controllerType} controller at $controller_path"
              log "Enabled buttons: ${concatStringsSep ", " buttons}"
              log "Starting event monitoring..."

              # Monitor controller events
              evtest "$controller_path" 2>/dev/null | while IFS= read -r line; do
                  ${generateButtonChecks buttons}
              done
          }

          # Main loop with hotplug support
          main() {
              log "Controller MangoHud Toggle Service started"
              log "Monitoring for ${controllerType} controllers..."
              log "Supported buttons: ${concatStringsSep ", " buttons}"

              while true; do
                  local controller_path
                  if controller_path=$(find_controller); then
                      log "Controller connected: $controller_path"
                      monitor_controller "$controller_path" || {
                          log "Controller monitoring failed, will retry..."
                      }
                  else
                      log "No controller found, waiting for connection..."
                  fi

                  # Wait before retrying
                  sleep 2

                  # Check for new devices using inotify if available
                  if command -v inotifywait >/dev/null 2>&1; then
                      log "Waiting for new input devices..."
                      timeout 30 inotifywait -e create /dev/input/ 2>/dev/null || true
                  fi
              done
          }

          # Handle signals gracefully
          trap 'log "Service stopping..."; exit 0' TERM INT

          main
        '';
      executable = true;
    };

    # SystemD service for MangoHud toggle
    systemd.user.services.controller-mangohud-toggle =
      mkIf (config.controller.mangohudToggle.enable && config.controller.mangohudToggle.autoStart)
        {
          Unit = {
            Description = "Controller MangoHud Toggle Service";
            After = [ "multi-user.target" ];
          };

          Service = {
            Type = "simple";
            ExecStart = "%h/bin/controller-mangohud-toggle.sh";
            Restart = "always";
            RestartSec = "5s";
            Environment = [
              "XDG_RUNTIME_DIR=/run/user/%i"
            ];
          };

          Install = {
            WantedBy = [ "default.target" ];
          };
        };

    # Steam overlay via a gamepad chord (default L3+R3). Over Moonlight there is
    # no keyboard and Steam Input is off for the Sunshine virtual pad, so the
    # pad's Guide button can't open the overlay — instead we watch the pad's
    # evdev node and inject the overlay hotkey (Shift+Tab) via hyprctl on the
    # chord. Same listener pattern as modules/games switch-quit-listener; both
    # open the pad read-only (no grab) and use distinct chords, so they coexist.
    systemd.user.services.controller-steam-overlay =
      mkIf config.controller.steamOverlay.enable (
        let
          so = config.controller.steamOverlay;
          # evdev key codes (Linux input-event-codes.h), Xbox pad layout.
          btnCodes = {
            a = 304; b = 305; x = 308; y = 307;
            l1 = 310; r1 = 311; l2 = 312; r2 = 313;
            select = 314; start = 315; guide = 316; l3 = 317; r3 = 318;
          };
          chordPy = "{" + concatMapStringsSep ", " (b: toString btnCodes.${b}) so.buttons + "}";
          script = pkgs.writeText "controller-steam-overlay.py" ''
            import os
            import re
            import select
            import struct
            import subprocess
            import time

            PAD_NAME = "${so.padName}"
            CHORD = ${chordPy}
            HOLD_SECONDS = ${toString so.holdSeconds}
            HYPRCTL = "${pkgs.hyprland}/bin/hyprctl"
            EVENT_FORMAT = "llHHi"
            EVENT_SIZE = struct.calcsize(EVENT_FORMAT)


            def find_pad():
                try:
                    blocks = open("/proc/bus/input/devices").read().split("\n\n")
                except OSError:
                    return None
                for block in blocks:
                    if PAD_NAME in block:
                        m = re.search(r"event(\d+)", block)
                        if m:
                            return "/dev/input/event" + m.group(1)
                return None


            def hypr_env():
                env = dict(os.environ)
                hypr_dir = os.path.join(env.get("XDG_RUNTIME_DIR", ""), "hypr")
                try:
                    sigs = sorted(
                        os.listdir(hypr_dir),
                        key=lambda s: os.path.getmtime(os.path.join(hypr_dir, s)),
                        reverse=True,
                    )
                    if sigs:
                        env["HYPRLAND_INSTANCE_SIGNATURE"] = sigs[0]
                except OSError:
                    pass
                return env


            def open_overlay():
                # Send Shift+Tab (Steam's overlay hotkey) to the focused window.
                subprocess.run(
                    [HYPRCTL, "dispatch", "sendshortcut", "SHIFT,TAB,activewindow"],
                    env=hypr_env(), stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                )


            while True:
                dev = find_pad()
                if dev is None:
                    time.sleep(2)
                    continue
                try:
                    fd = os.open(dev, os.O_RDONLY)
                except OSError:
                    time.sleep(2)
                    continue
                down = {}
                fired = False
                try:
                    while True:
                        ready, _, _ = select.select([fd], [], [], 0.2)
                        if ready:
                            data = os.read(fd, EVENT_SIZE)
                            if len(data) < EVENT_SIZE:
                                break
                            _, _, etype, code, value = struct.unpack(EVENT_FORMAT, data)
                            if etype == 1 and code in CHORD:
                                if value == 1:
                                    down[code] = time.monotonic()
                                elif value == 0:
                                    down.pop(code, None)
                                    fired = False
                        if (
                            not fired
                            and len(down) == len(CHORD)
                            and time.monotonic() - max(down.values()) >= HOLD_SECONDS
                        ):
                            fired = True
                            open_overlay()
                except OSError:
                    pass  # pad unplugged (Moonlight disconnect) — rediscover
                finally:
                    os.close(fd)
          '';
        in
        {
          Unit = {
            Description = "Open Steam overlay from a gamepad chord on the streamed pad";
            After = [ "graphical-session.target" ];
          };

          Service = {
            Type = "simple";
            ExecStart = "${pkgs.python3}/bin/python3 ${script}";
            Restart = "always";
            RestartSec = "5s";
          };

          Install = {
            WantedBy = [ "default.target" ];
          };
        }
      );

    # Custom controller mappings script (future expansion)
    home.file."bin/controller-custom-mappings.sh" = mkIf config.controller.customMappings.enable {
      text = ''
        #!${pkgs.bash}/bin/bash
        # Custom controller mappings
        # This can be expanded for additional custom commands
        echo "Custom controller mappings not yet implemented"
      '';
      executable = true;
    };

    # Controller configuration hints
    home.file."docs/controller-usage.md" = {
      text = ''
        # Controller Configuration

        ## Current Setup
        - Controller Type: ${config.controller.type}
        - MangoHud Toggle: ${if config.controller.mangohudToggle.enable then "Enabled" else "Disabled"}
        ${optionalString config.controller.mangohudToggle.enable "- Toggle Buttons: ${concatStringsSep ", " config.controller.mangohudToggle.buttons}"}
        - Auto-start Service: ${
          if config.controller.mangohudToggle.autoStart then "Enabled" else "Disabled"
        }

        ## Usage
        ${optionalString config.controller.mangohudToggle.enable ''
          ### MangoHud Toggle
          Press any of the configured buttons (${concatStringsSep ", " config.controller.mangohudToggle.buttons}) to toggle MangoHud on/off while gaming.
        ''}

        ## Manual Control
        - Start monitoring: `systemctl --user start controller-mangohud-toggle`
        - Stop monitoring: `systemctl --user stop controller-mangohud-toggle`
        - Check status: `systemctl --user status controller-mangohud-toggle`
        - Run manually: `~/bin/controller-mangohud-toggle.sh`

        ## Troubleshooting
        - Check connected controllers: `cat /proc/bus/input/devices | grep -i controller`
        - Test controller input: `evtest /dev/input/eventXX`
        - View service logs: `journalctl --user -u controller-mangohud-toggle -f`
      '';
    };
  };
}
