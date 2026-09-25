{
  config,
  lib,
  pkgs,
  ...
}:
with lib;

let
  cfg = config.my.controls.utils;

  # Build notification commands using the notifications module
  notifyTime = optionalString cfg.time (
    config.my.notifications.send {
      category = "time";
      summary = "\$(date '+%H:%M')";
      body = "\$(date '+%A %-d %B %Y')";
    }
  );

  notifyWorkspace = optionalString cfg.workspaces (
    config.my.notifications.send {
      category = "workspace";
      summary = "Workspace \$currentWorkspace";
      body = "\$notification";
    }
  );

  notifyBattery = optionalString cfg.battery (
    config.my.notifications.send {
      category = "battery";
      summary = "\$headline";
      body = "\$percent%\$time_info";
      progress = "\$percent";
    }
  );

  notifySystem = optionalString cfg.system (
    config.my.notifications.send {
      category = "system";
      summary = "System load";
      body = "CPU \$cpu · Mem \$memUsedPercent% · Disk \$deviceUsedPercent%";
    }
  );

  # Window manager specific workspace commands
  workspaceCommands = {
    hyprland = ''
      currentWorkspace=$(${pkgs.hyprland}/bin/hyprctl activeworkspace | grep "workspace\sID" | awk '{print($3)}')
      displays=$(${pkgs.hyprland}/bin/hyprctl workspaces | grep "workspace ID" | awk '{print($7)}' | sort -u)
      notification=""

      for display in $displays; do
        notification+="$display"$'\n'

        workspaces=$(${pkgs.hyprland}/bin/hyprctl workspaces | grep "workspace\sID" | grep "\s''${display}" | awk '{print($3)}')
        for workspace in $workspaces; do
          if [ "$workspace" == "$currentWorkspace" ]; then
            notification+="  → $workspace"$'\n'
          else
            notification+="    $workspace"$'\n'
          fi
        done
      done
    '';
    i3 = ''
      currentWorkspace=$(${pkgs.i3}/bin/i3-msg -t get_workspaces | ${pkgs.jq}/bin/jq -r '.[] | select(.focused==true).name')
      workspaces=$(${pkgs.i3}/bin/i3-msg -t get_workspaces | ${pkgs.jq}/bin/jq -r '.[].name')
      notification=""
      for workspace in $workspaces; do
        if [ "$workspace" == "$currentWorkspace" ]; then
          notification+="  → $workspace"$'\n'
        else
          notification+="    $workspace"$'\n'
        fi
      done
    '';
    sway = ''
      currentWorkspace=$(${pkgs.sway}/bin/swaymsg -t get_workspaces | ${pkgs.jq}/bin/jq -r '.[] | select(.focused==true).name')
      workspaces=$(${pkgs.sway}/bin/swaymsg -t get_workspaces | ${pkgs.jq}/bin/jq -r '.[].name')
      notification=""
      for workspace in $workspaces; do
        if [ "$workspace" == "$currentWorkspace" ]; then
          notification+="  → $workspace"$'\n'
        else
          notification+="    $workspace"$'\n'
        fi
      done
    '';
    niri = ''
      # Get workspace info from niri
      workspaceJson=$(niri msg -j workspaces)
      currentWorkspace=$(echo "$workspaceJson" | ${pkgs.jq}/bin/jq -r '.[] | select(.is_focused==true).idx')
      notification=""

      # Group by output
      outputs=$(echo "$workspaceJson" | ${pkgs.jq}/bin/jq -r '.[].output' | sort -u)
      for output in $outputs; do
        notification+="$output:"$'\n'
        workspaces=$(echo "$workspaceJson" | ${pkgs.jq}/bin/jq -r ".[] | select(.output==\"$output\") | .idx")
        for workspace in $workspaces; do
          if [ "$workspace" == "$currentWorkspace" ]; then
            notification+="  → $workspace"$'\n'
          else
            notification+="    $workspace"$'\n'
          fi
        done
      done
    '';
    generic = ''
      currentWorkspace="N/A"
      notification="Workspace info not available for this window manager"
    '';
  };

  # Follow the accelerometer (iio-sensor-proxy) and rotate the built-in panel
  rotationOutput =
    if config.my.window-manager.touchOutput != null then
      config.my.window-manager.touchOutput
    else
      "eDP-1";
  # monitor-sensor orientation -> the compositor's transform
  rotateCommand =
    {
      hyprland =
        transform:
        ''${pkgs.hyprland}/bin/hyprctl keyword monitor "${rotationOutput},preferred,auto,1,transform,${transform.hyprland}"'';
      niri =
        transform:
        "${config.programs.niri.package}/bin/niri msg output ${rotationOutput} transform ${transform.niri}";
    }
    .${config.my.controls.windowManager} or null;
  transforms = {
    normal = {
      hyprland = "0";
      niri = "normal";
    };
    left-up = {
      hyprland = "1";
      niri = "90";
    };
    bottom-up = {
      hyprland = "2";
      niri = "180";
    };
    right-up = {
      hyprland = "3";
      niri = "270";
    };
  };
  autoScreenRotationCommand = optionalString (cfg.autoScreenRotation && rotateCommand != null) ''
    ${pkgs.iio-sensor-proxy}/bin/monitor-sensor | while read -r line; do
      [ "$(echo "$line" | ${pkgs.gawk}/bin/awk '{print($1)}')" = "Accelerometer" ] || continue
      case "$(echo "$line" | ${pkgs.gawk}/bin/awk '{print($4)}')" in
        ${concatStrings (
          mapAttrsToList (orientation: t: "${orientation}) ${rotateCommand t} ;;\n        ") transforms
        )}
      esac
    done
  '';

  timeNotifier = mkIf cfg.time (
    pkgs.writeShellScriptBin "time-notifier" ''
      #!/usr/bin/env bash
      ${notifyTime}
    ''
  );

  workspaceNotifier = mkIf cfg.workspaces (
    pkgs.writeShellScriptBin "workspace-notifier" ''
      #!/usr/bin/env bash
      ${workspaceCommands.${config.my.controls.windowManager}}
      ${notifyWorkspace}
    ''
  );

  batteryNotifier = mkIf cfg.battery (
    pkgs.writeShellScriptBin "battery-notifier" ''
      #!/usr/bin/env bash

      battery_info=$(${pkgs.upower}/bin/upower -i `${pkgs.upower}/bin/upower -e | grep 'BAT'`)
      percent=$(echo "$battery_info" | grep percentage | awk '{print($2)}' | sed 's/%//')
      status=$(echo "$battery_info" | grep state | awk '{print($2)}')

      # Get time remaining/until full
      time_info=""
      if [ "$status" == "discharging" ]; then
        time_remaining=$(echo "$battery_info" | grep "time to empty" | awk '{print $4, $5}')
        if [ -n "$time_remaining" ]; then
          time_info=" · $time_remaining left"
        fi
      elif [ "$status" == "charging" ]; then
        time_until_full=$(echo "$battery_info" | grep "time to full" | awk '{print $4, $5}')
        if [ -n "$time_until_full" ]; then
          time_info=" · $time_until_full to full"
        fi
      fi

      case "$status" in
        charging)      headline="Charging";;
        discharging)   headline="Discharging";;
        fully-charged) headline="Fully charged";;
        *)             headline="$status";;
      esac

      ${notifyBattery}
    ''
  );

  systemNotifier = mkIf cfg.system (
    pkgs.writeShellScriptBin "system-notifier" ''
      #!/usr/bin/env bash

      cpu=$(${pkgs.procps}/bin/top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1"%"}')

      totalMem=$(${pkgs.procps}/bin/free -m | grep Mem | awk '{print $2}')
      totalMem=$(echo "scale=2; $totalMem / 1024" | ${pkgs.bc}/bin/bc)

      usedMem=$(${pkgs.procps}/bin/free -m | grep Mem | awk '{print $3}')
      usedMem=$(echo "scale=2; $usedMem / 1024" | ${pkgs.bc}/bin/bc)

      memUsedPercent=$(echo "scale=1; $usedMem * 100 / $totalMem" | ${pkgs.bc}/bin/bc)

      # Usage of the filesystem mounted at /, whatever device backs it
      deviceUsedPercent=$(${pkgs.coreutils}/bin/df --output=pcent / | tail -n 1 | tr -dc '0-9')

      ${notifySystem}
    ''
  );

  autoScreenRotation = (
    pkgs.writeShellScriptBin "auto-screen-rotation" ''
      #!/usr/bin/env bash
      ${autoScreenRotationCommand}
    ''
  );

in
{
  config = mkIf (config.my.controls.enable && cfg.enable) {
    # Rotation only while folded into tablet mode: a watcher follows the
    # tablet-mode switch (libinput; there is no udev event for it) and starts
    # the accelerometer loop on entry, stops it and restores the normal
    # orientation on exit. Needs read access to input devices (the `input`
    # group, granted by the NixOS half of this module).
    systemd.user.services = mkIf cfg.autoScreenRotation {
      auto-screen-rotation = {
        Unit.Description = "Rotate the built-in panel with the accelerometer (tablet mode)";
        Service = {
          ExecStart = "${autoScreenRotation}/bin/auto-screen-rotation";
          ExecStopPost = optional (rotateCommand != null) (
            pkgs.writeShellScript "reset-rotation" (rotateCommand transforms.normal)
          );
        };
      };
      tablet-mode-watch = {
        Unit = {
          Description = "Start/stop screen rotation with the tablet-mode switch";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
        };
        Service = {
          ExecStart = pkgs.writeShellScript "tablet-mode-watch" ''
            ${pkgs.coreutils}/bin/stdbuf -oL ${pkgs.libinput.bin}/bin/libinput debug-events \
              | ${pkgs.gnugrep}/bin/grep --line-buffered 'switch tablet-mode' \
              | while read -r line; do
                  case "$line" in
                    *"state 1"*) ${pkgs.systemd}/bin/systemctl --user start auto-screen-rotation ;;
                    *"state 0"*) ${pkgs.systemd}/bin/systemctl --user stop auto-screen-rotation ;;
                  esac
                done
          '';
          Restart = "on-failure";
          RestartSec = 5;
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };
    };

    home.packages =
      with pkgs;
      [
        # Common utilities
        bc
        util-linux
        upower
      ]
      ++ optionals cfg.time [
        timeNotifier
      ]
      ++ optionals cfg.workspaces [
        workspaceNotifier
      ]
      ++ optionals cfg.battery [
        batteryNotifier
      ]
      ++ optionals cfg.system [
        systemNotifier
      ]
      ++ optionals cfg.autoScreenRotation [
        autoScreenRotation
        iio-sensor-proxy
      ]
      ++
        optionals
          (
            cfg.workspaces
            && (
              config.my.controls.windowManager == "i3"
              || config.my.controls.windowManager == "sway"
              || config.my.controls.windowManager == "niri"
            )
          )
          [
            jq
          ];
  };
}
