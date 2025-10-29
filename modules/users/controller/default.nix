{ config, lib, pkgs, ... }:

with lib;

{
  options.controller = {
    enable = mkEnableOption "Enable controller support and custom mappings";

    type = mkOption {
      type = types.enum [ "ps5" "xbox" "generic" ];
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
        type = types.listOf (types.enum [ "square" "triangle" "circle" "x" "share" "options" "l3" "r3" ]);
        default = [ "square" "triangle" ];
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
        default = {};
        example = {
          "l3+r3" = "screenshot";
          "share+options" = "record";
        };
        description = "Custom button combination to command mappings";
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
    home.packages = with pkgs; [
      evtest
      coreutils
      inotify-tools
      wtype
      procps
      xdotool
      ydotool
      python3
    ] ++ optionals config.controller.customMappings.enable [
      # Add additional packages for custom mappings if needed
    ];

    # Add udev rules for controller access (needs to be in system config)
    home.file."docs/controller-udev-rules.txt" = {
      text = ''
        # To fix controller access for multiple users, add these udev rules to your system configuration:
        
        # In your NixOS configuration (/etc/nixos/configuration.nix), add:
        services.udev.extraRules = '''
          # PlayStation controllers
          KERNEL=="event*", ATTRS{name}=="DualSense Wireless Controller", MODE="0666", GROUP="input"
          KERNEL=="js*", ATTRS{name}=="DualSense Wireless Controller", MODE="0666", GROUP="input"
          
          # Xbox controllers  
          KERNEL=="event*", ATTRS{name}=="Xbox*Controller*", MODE="0666", GROUP="input"
          KERNEL=="js*", ATTRS{name}=="Xbox*Controller*", MODE="0666", GROUP="input"
          
          # Generic controllers
          KERNEL=="event*", SUBSYSTEM=="input", ENV{ID_INPUT_JOYSTICK}=="1", MODE="0666", GROUP="input"
          KERNEL=="js*", SUBSYSTEM=="input", MODE="0666", GROUP="input"
        ''';
        
        # Then rebuild your system: sudo nixos-rebuild switch
      '';
    };

    # MangoHud toggle script
    home.file."bin/controller-mangohud-toggle.sh" = mkIf config.controller.mangohudToggle.enable {
      text = let
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

        generateButtonChecks = buttons: let
          currentMappings = buttonMappings.${controllerType};
          buttonChecks = map (btn: 
            ''if echo "$line" | ${pkgs.gnugrep}/bin/grep -q "${currentMappings.${btn}}.*value 1"; then
        # Only process if not in cooldown
        current_time=$(${pkgs.coreutils}/bin/date +%s)
        if [ ! -f "/tmp/mangohud_cooldown" ] || [ "$current_time" -gt "$(${pkgs.coreutils}/bin/cat /tmp/mangohud_cooldown 2>/dev/null || echo 0)" ]; then
            ${pkgs.coreutils}/bin/echo "${btn} button pressed - toggling MangoHud..."
            toggle_mangohud
            ${pkgs.coreutils}/bin/echo "MangoHud toggled with ${btn}!"
            # Set cooldown for 2 seconds
            ${pkgs.coreutils}/bin/echo "$((current_time + 2))" > /tmp/mangohud_cooldown
        fi
    fi''
          ) buttons;
        in concatStringsSep "\n        " buttonChecks;

      in ''
        #!${pkgs.bash}/bin/bash
        # Controller to MangoHud toggle script (Gamescope compatible)
        # Generated by NixOS controller module
        
        set -euo pipefail
        
        # Logging function
        log() {
            echo "[$(${pkgs.coreutils}/bin/date '+%Y-%m-%d %H:%M:%S')] $*" >&2
        }
        
        # MangoHud toggle function for gamescope
        toggle_mangohud() {
            # Method 1: Try to find and signal the gamescope process
            if ${pkgs.procps}/bin/pgrep -f "gamescope" >/dev/null; then
                log "Found gamescope process, toggling MangoHud via Steam/gamescope integration"
                
                # Use Steam's console command system and gamescope integration
                # This is the most reliable method for Steam Big Picture + gamescope
                
                local toggle_success=false
                
                # Method 1: Use Steam console commands via named pipe or socket
                local steam_pid=$(${pkgs.procps}/bin/pgrep -f "steam.*bigpicture")
                if [ -n "$steam_pid" ]; then
                    log "Found Steam Big Picture process, attempting console command"
                    # Steam Big Picture has console commands that can be triggered
                    # Try to use Steam's overlay toggle
                    if ${pkgs.coreutils}/bin/kill -USR2 "$steam_pid" 2>/dev/null; then
                        log "Sent overlay toggle signal to Steam"
                        toggle_success=true
                    fi
                fi
                
                # Method 2: Use gamescope's built-in hotkey system by simulating input
                if [ "$toggle_success" = false ]; then
                    log "Trying gamescope hotkey simulation"
                    local gamescope_pid=$(${pkgs.procps}/bin/pgrep -f "gamescope")
                    if [ -n "$gamescope_pid" ]; then
                        # Send the standard overlay toggle signal to gamescope
                        if ${pkgs.coreutils}/bin/kill -USR1 "$gamescope_pid" 2>/dev/null; then
                            log "Sent overlay toggle signal to gamescope"
                            toggle_success=true
                        fi
                    fi
                fi
                
                # Method 3: Use simple script to send F9
                if [ "$toggle_success" = false ]; then
                    log "Attempting simple F9 key injection"
                    
                    # Try a much simpler approach
                    if ${pkgs.coreutils}/bin/command -v ${pkgs.python3}/bin/python3 >/dev/null 2>&1; then
                        ${pkgs.python3}/bin/python3 -c 'import struct; f=open("/dev/input/event0","wb"); f.write(struct.pack("llHHI",0,0,1,67,1)); f.write(struct.pack("llHHI",0,0,0,0,0)); f.write(struct.pack("llHHI",0,0,1,67,0)); f.write(struct.pack("llHHI",0,0,0,0,0)); f.close()' 2>/dev/null && {
                            toggle_success=true
                            log "F9 sent via event0"
                        }
                    fi
                fi
                
                if [ "$toggle_success" = false ]; then
                    log "All MangoHud toggle methods failed"
                fi
            else
                log "No gamescope process found, trying alternative methods"
                # Method 2: Toggle via MangoHud control file if it exists
                if [ -w "/tmp/mangohud_toggle" ]; then
                    ${pkgs.coreutils}/bin/echo "toggle" > /tmp/mangohud_toggle
                elif [ -w "/run/user/$(${pkgs.coreutils}/bin/id -u)/mangohud_toggle" ]; then
                    ${pkgs.coreutils}/bin/echo "toggle" > "/run/user/$(${pkgs.coreutils}/bin/id -u)/mangohud_toggle"
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
            controller_event=$(${pkgs.coreutils}/bin/cat /proc/bus/input/devices 2>/dev/null | \
                ${pkgs.gnugrep}/bin/grep -B 5 -A 5 "$controller_name" | \
                ${pkgs.gnugrep}/bin/grep "Handlers" | \
                ${pkgs.gnugrep}/bin/grep -o "event[0-9]*" | \
                ${pkgs.coreutils}/bin/head -1)
            
            if [ -n "$controller_event" ]; then
                ${pkgs.coreutils}/bin/echo "/dev/input/$controller_event"
                return 0
            fi
            return 1
        }
        
        # Monitor single controller
        monitor_controller() {
            local controller_path="$1"
            
            if [ ! -r "$controller_path" ]; then
                log "ERROR: No read permission for $controller_path"
                log "Current user: $(${pkgs.coreutils}/bin/whoami), Groups: $(${pkgs.coreutils}/bin/groups)"
                log "Device permissions: $(${pkgs.coreutils}/bin/ls -la "$controller_path" 2>/dev/null || ${pkgs.coreutils}/bin/echo "Device not found")"
                return 1
            fi
            
            log "Successfully found ${controllerType} controller at $controller_path"
            log "Enabled buttons: ${concatStringsSep ", " buttons}"
            log "Starting event monitoring..."
            
            # Monitor controller events
            ${pkgs.evtest}/bin/evtest "$controller_path" 2>/dev/null | while IFS= read -r line; do
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
                ${pkgs.coreutils}/bin/sleep 2
                
                # Check for new devices using inotify if available
                if ${pkgs.coreutils}/bin/command -v ${pkgs.inotify-tools}/bin/inotifywait >/dev/null 2>&1; then
                    log "Waiting for new input devices..."
                    ${pkgs.coreutils}/bin/timeout 30 ${pkgs.inotify-tools}/bin/inotifywait -e create /dev/input/ 2>/dev/null || true
                fi
            done
        }
        
        # Handle signals gracefully - ignore USR1 to prevent crashes
        trap 'log "Service stopping..."; exit 0' TERM INT
        trap 'log "Received USR1 signal, ignoring..."; true' USR1
        
        main
      '';
      executable = true;
    };

    # SystemD service for MangoHud toggle
    systemd.user.services.controller-mangohud-toggle = mkIf (config.controller.mangohudToggle.enable && config.controller.mangohudToggle.autoStart) {
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

      Install = { WantedBy = [ "default.target" ]; };
    };

    # Custom controller mappings script (future expansion)
    home.file."bin/controller-custom-mappings.sh" = mkIf config.controller.customMappings.enable {
      text = ''
        #!${pkgs.bash}/bin/bash
        # Custom controller mappings
        # This can be expanded for additional custom commands
        ${pkgs.coreutils}/bin/echo "Custom controller mappings not yet implemented"
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
        - Auto-start Service: ${if config.controller.mangohudToggle.autoStart then "Enabled" else "Disabled"}

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
        - Check connected controllers: `${pkgs.coreutils}/bin/cat /proc/bus/input/devices | ${pkgs.gnugrep}/bin/grep -i controller`
        - Test controller input: `${pkgs.evtest}/bin/evtest /dev/input/eventXX`
        - View service logs: `journalctl --user -u controller-mangohud-toggle -f`
      '';
    };
  };
}