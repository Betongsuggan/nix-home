{ pkgs, ... }:
{
  time = pkgs.writeShellScriptBin "time-notifier" ''
    #!/usr/bin/env bash
    ${pkgs.dunst}/bin/dunstify -u low -i clock -h string:x-dunst-stack-tag:timeNotifier -a "Time" "$(date --rfc-3339=seconds)" '';

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
    
    ${pkgs.dunst}/bin/dunstify -u low -i system -h string:x-dunst-stack-tag:workspaceNotifier -a "Workspaces" "Current: ''${currentWorkspace}" "''${notification}"
  '';

  battery = pkgs.writeShellScriptBin "battery-notifier" ''
    #!/usr/bin/env bash
    
    percent=$(upower -i `upower -e | grep 'BAT'` | grep percentage | awk '{print($2)}' | sed 's/%//')
    status=$(upower -i `upower -e | grep 'BAT'` | grep state | awk '{print($2)}')

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
    
    ${pkgs.dunst}/bin/dunstify -h string:x-dunst-stack-tag:batteryNotifier -i battery -a 'Battery' "" "<b>State</b>: $status\n<b>Percent</b>:$percent%"
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
    
    ${pkgs.dunst}/bin/dunstify -h string:x-dunst-stack-tag:batteryNotifier -i cpu -a 'System' "" "<b>CPU</b>: $cpu 🧠\n<b>Memory</b>: $memUsedPercent% $usedMem GB| $totalMem GB🪜\n<b>Storage</b>: $deviceUsedPercent% $deviceUsed GB| $deviceCapacity GB 🪣"
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
