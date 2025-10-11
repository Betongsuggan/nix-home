{ config, pkgs, ... }:
let
  # Build notification commands using the notifications module
  notifyTime = config.notifications.send {
    urgency = "low";
    icon = "clock";
    appName = "Time";
    summary = "\$(date --rfc-3339=seconds)";
    hints = {
      "string:x-dunst-stack-tag" = "timeNotifier";
    };
  };

  notifyWorkspace = config.notifications.send {
    urgency = "low";
    icon = "system";
    appName = "Workspaces";
    summary = "Current: \$currentWorkspace";
    body = "\$notification";
    hints = {
      "string:x-dunst-stack-tag" = "workspaceNotifier";
    };
  };

  notifyBattery = config.notifications.send {
    urgency = "low";
    icon = "battery";
    appName = "Battery";
    summary = "";
    body = "<b>State</b>: \$status\\n<b>Percent</b>: \$percent%\$time_info";
    hints = {
      "string:x-dunst-stack-tag" = "batteryNotifier";
    };
  };

  notifySystem = config.notifications.send {
    urgency = "low";
    icon = "cpu";
    appName = "System";
    summary = "";
    body = "<b>CPU</b>: \$cpu 🧠\\n<b>Memory</b>: \$memUsedPercent% \$usedMem GB| \$totalMem GB🪜\\n<b>Storage</b>: \$deviceUsedPercent% \$deviceUsed GB| \$deviceCapacity GB 🪣";
    hints = {
      "string:x-dunst-stack-tag" = "systemNotifier";
    };
  };

in {
  time = pkgs.writeShellScriptBin "time-notifier" ''
    #!/usr/bin/env bash
    ${notifyTime}
  '';

  workspaces = pkgs.writeShellScriptBin "workspace-notifier" ''
    #!/usr/bin/env bash

    currentWorkspace=$(hyprctl activeworkspace | grep "workspace\sID" | awk '{print($3)}')
    displays=$(hyprctl workspaces | grep "workspace ID" | awk '{print($7)}' | sort -u)
    notification=""

    for display in $displays; do
      notification+="$display\n"

      workspaces=$(hyprctl workspaces | grep "workspace\sID" | grep "\s''${display}" | awk '{print($3)}')
      for workspace in $workspaces; do
        if [ "$workspace" == "$currentWorkspace" ]; then
          notification+="  $workspace\n"
        else
          notification+="  $workspace\n"
        fi
      done
    done

    ${notifyWorkspace}
  '';

  battery = pkgs.writeShellScriptBin "battery-notifier" ''
    #!/usr/bin/env bash

    battery_info=$(upower -i `upower -e | grep 'BAT'`)
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
  '';

  system = pkgs.writeShellScriptBin "system-notifier" ''
    #!/usr/bin/env bash

    cpu=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1"%"}')

    totalMem=$(free -m | grep Mem | awk '{print $2}')
    totalMem=$(echo "scale=2; $totalMem / 1024" | ${pkgs.bc}/bin/bc)

    usedMem=$(free -m | grep Mem | awk '{print $3}')
    usedMem=$(echo "scale=2; $usedMem / 1024" | ${pkgs.bc}/bin/bc)

    memUsedPercent=$(echo "scale=1; $usedMem * 100 / $totalMem" | ${pkgs.bc}/bin/bc)

    rootDevice=$(lsblk -o NAME,MOUNTPOINT | grep '/$' | awk '{print($1)}' | sed 's/[^a-z0-9]*//')
    deviceCapacity=$(df -h | grep nvme0n1p7 | awk '{print($2)}' | sed 's/[^0-9]//')
    deviceUsed=$(df -h | grep nvme0n1p7 | awk '{print($3)}' | sed 's/[^0-9]//')

    deviceUsedPercent=$(echo "scale=1; $deviceUsed * 100 / $deviceCapacity" | ${pkgs.bc}/bin/bc)

    ${notifySystem}
  '';

  autoScreenRotation = pkgs.writeShellScriptBin "auto-screen-rotation" ''
    #!/usr/bin/env bash

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
}
