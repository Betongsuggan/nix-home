{ config, lib, pkgs, ... }:
with lib;

let
  cfg = config.controls.utils;
  
  # Build notification commands using the notifications module
  notifyTime = optionalString cfg.time (config.notifications.send {
    urgency = "low";
    icon = "clock";
    appName = "Time";
    summary = "\$(date --rfc-3339=seconds)";
    hints = {
      "string:x-dunst-stack-tag" = "timeNotifier";
    };
  });

  notifyWorkspace = optionalString cfg.workspaces (config.notifications.send {
    urgency = "low";
    icon = "system";
    appName = "Workspaces";
    summary = "Current: \$currentWorkspace";
    body = "\$notification";
    hints = {
      "string:x-dunst-stack-tag" = "workspaceNotifier";
    };
  });

  notifyBattery = optionalString cfg.battery (config.notifications.send {
    urgency = "low";
    icon = "battery";
    appName = "Battery";
    summary = "";
    body = "<b>State</b>: \$status\\n<b>Percent</b>: \$percent%\$time_info";
    hints = {
      "string:x-dunst-stack-tag" = "batteryNotifier";
    };
  });

  notifySystem = optionalString cfg.system (config.notifications.send {
    urgency = "low";
    icon = "cpu";
    appName = "System";
    summary = "";
    body = "<b>CPU</b>: \$cpu 🧠\\n<b>Memory</b>: \$memUsedPercent% \$usedMem GB| \$totalMem GB🪜\\n<b>Storage</b>: \$deviceUsedPercent% \$deviceUsed GB| \$deviceCapacity GB 🪣";
    hints = {
      "string:x-dunst-stack-tag" = "systemNotifier";
    };
  });

  # Window manager specific workspace commands
  workspaceCommands = {
    hyprland = ''
      currentWorkspace=$(${pkgs.hyprland}/bin/hyprctl activeworkspace | grep "workspace\sID" | awk '{print($3)}')
      displays=$(${pkgs.hyprland}/bin/hyprctl workspaces | grep "workspace ID" | awk '{print($7)}' | sort -u)
      notification=""

      for display in $displays; do
        notification+="$display\n"

        workspaces=$(${pkgs.hyprland}/bin/hyprctl workspaces | grep "workspace\sID" | grep "\s''${display}" | awk '{print($3)}')
        for workspace in $workspaces; do
          if [ "$workspace" == "$currentWorkspace" ]; then
            notification+="  $workspace\n"
          else
            notification+="  $workspace\n"
          fi
        done
      done
    '';
    i3 = ''
      currentWorkspace=$(${pkgs.i3}/bin/i3-msg -t get_workspaces | ${pkgs.jq}/bin/jq -r '.[] | select(.focused==true).name')
      workspaces=$(${pkgs.i3}/bin/i3-msg -t get_workspaces | ${pkgs.jq}/bin/jq -r '.[].name')
      notification="Workspaces:\n"
      for workspace in $workspaces; do
        if [ "$workspace" == "$currentWorkspace" ]; then
          notification+="  → $workspace\n"
        else
          notification+="    $workspace\n"
        fi
      done
    '';
    sway = ''
      currentWorkspace=$(${pkgs.sway}/bin/swaymsg -t get_workspaces | ${pkgs.jq}/bin/jq -r '.[] | select(.focused==true).name')
      workspaces=$(${pkgs.sway}/bin/swaymsg -t get_workspaces | ${pkgs.jq}/bin/jq -r '.[].name')
      notification="Workspaces:\n"
      for workspace in $workspaces; do
        if [ "$workspace" == "$currentWorkspace" ]; then
          notification+="  → $workspace\n"
        else
          notification+="    $workspace\n"
        fi
      done
    '';
    niri = ''
      # Get workspace info from niri
      workspaceJson=$(niri msg -j workspaces)
      currentWorkspace=$(echo "$workspaceJson" | ${pkgs.jq}/bin/jq -r '.[] | select(.is_focused==true).idx')
      notification="Workspaces:\n"

      # Group by output
      outputs=$(echo "$workspaceJson" | ${pkgs.jq}/bin/jq -r '.[].output' | sort -u)
      for output in $outputs; do
        notification+="$output:\n"
        workspaces=$(echo "$workspaceJson" | ${pkgs.jq}/bin/jq -r ".[] | select(.output==\"$output\") | .idx")
        for workspace in $workspaces; do
          if [ "$workspace" == "$currentWorkspace" ]; then
            notification+="  → $workspace\n"
          else
            notification+="    $workspace\n"
          fi
        done
      done
    '';
    generic = ''
      currentWorkspace="N/A"
      notification="Workspace info not available for this window manager"
    '';
  };

  autoScreenRotationCommand = optionalString (cfg.autoScreenRotation && config.controls.windowManager == "hyprland") ''
    ${pkgs.iio-sensor-proxy}/bin/monitor-sensor |
    while read -r line; do
      change=$(echo "$line" | awk '{print($1)}')
      if [ "$change" == "Accelerometer" ]
      then
        rotation=$(echo "$line" | awk '{print($4)}')
        transform=0
        if [ "$rotation" == 'right-up' ]
        then
          transform=3
        elif [ "$rotation" == 'left-up' ]
        then
          transform=1
        elif [ "$rotation" == 'bottom-up' ]
        then
          transform=2
        fi

        ${pkgs.hyprland}/bin/hyprctl keyword monitor "eDP-1,preferred,auto,1,transform,$transform"
      fi
    done
  '';

  timeNotifier = mkIf cfg.time (pkgs.writeShellScriptBin "time-notifier" ''
    #!/usr/bin/env bash
    ${notifyTime}
  '');

  workspaceNotifier = mkIf cfg.workspaces (pkgs.writeShellScriptBin "workspace-notifier" ''
    #!/usr/bin/env bash
    ${workspaceCommands.${config.controls.windowManager}}
    ${notifyWorkspace}
  '');

  batteryNotifier = mkIf cfg.battery (pkgs.writeShellScriptBin "battery-notifier" ''
    #!/usr/bin/env bash

    battery_info=$(${pkgs.upower}/bin/upower -i `${pkgs.upower}/bin/upower -e | grep 'BAT'`)
    percent=$(echo "$battery_info" | grep percentage | awk '{print($2)}' | sed 's/%//')
    status=$(echo "$battery_info" | grep state | awk '{print($2)}')

    # Get time remaining/until full
    time_info=""
    if [ "$status" == "discharging" ]; then
      time_remaining=$(echo "$battery_info" | grep "time to empty" | awk '{print $4, $5}')
      if [ -n "$time_remaining" ]; then
        time_info="\n<b>Time left</b>: $time_remaining"
      fi
    elif [ "$status" == "charging" ]; then
      time_until_full=$(echo "$battery_info" | grep "time to full" | awk '{print $4, $5}')
      if [ -n "$time_until_full" ]; then
        time_info="\n<b>Time to full</b>: $time_until_full"
      fi
    fi

    if [ "$status" == "charging" ]
    then
      status="''${status} 🔌"
    elif [ "$status" == "discharging" ]
    then
      status="''${status} 🔋"
    elif [ "$status" == "fully-charged" ]
    then
      status="''${status} 💯"
    fi

    ${notifyBattery}
  '');

  systemNotifier = mkIf cfg.system (pkgs.writeShellScriptBin "system-notifier" ''
    #!/usr/bin/env bash

    cpu=$(${pkgs.procps}/bin/top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1"%"}')

    totalMem=$(${pkgs.procps}/bin/free -m | grep Mem | awk '{print $2}')
    totalMem=$(echo "scale=2; $totalMem / 1024" | ${pkgs.bc}/bin/bc)

    usedMem=$(${pkgs.procps}/bin/free -m | grep Mem | awk '{print $3}')
    usedMem=$(echo "scale=2; $usedMem / 1024" | ${pkgs.bc}/bin/bc)

    memUsedPercent=$(echo "scale=1; $usedMem * 100 / $totalMem" | ${pkgs.bc}/bin/bc)

    rootDevice=$(${pkgs.util-linux}/bin/lsblk -o NAME,MOUNTPOINT | grep '/$' | awk '{print($1)}' | sed 's/[^a-z0-9]*//')
    deviceCapacity=$(${pkgs.coreutils}/bin/df -h | grep nvme0n1p7 | awk '{print($2)}' | sed 's/[^0-9]//')
    deviceUsed=$(${pkgs.coreutils}/bin/df -h | grep nvme0n1p7 | awk '{print($3)}' | sed 's/[^0-9]//')

    deviceUsedPercent=$(echo "scale=1; $deviceUsed * 100 / $deviceCapacity" | ${pkgs.bc}/bin/bc)

    ${notifySystem}
  '');

  autoScreenRotation = mkIf cfg.autoScreenRotation (pkgs.writeShellScriptBin "auto-screen-rotation" ''
    #!/usr/bin/env bash
    ${autoScreenRotationCommand}
  '');

in
{
  config = mkIf (config.controls.enable && cfg.enable) {
    home.packages = with pkgs; [
      # Common utilities
      bc
      util-linux
      upower
    ] ++ optionals cfg.time [
      timeNotifier
    ] ++ optionals cfg.workspaces [
      workspaceNotifier
    ] ++ optionals cfg.battery [
      batteryNotifier
    ] ++ optionals cfg.system [
      systemNotifier
    ] ++ optionals cfg.autoScreenRotation [
      autoScreenRotation
      iio-sensor-proxy
    ] ++ optionals (cfg.workspaces && (config.controls.windowManager == "i3" || config.controls.windowManager == "sway" || config.controls.windowManager == "niri")) [
      jq
    ];
  };
}