{ pkgs, ... }:
{
  time = pkgs.writeShellScriptBin "time-notifier" ''
    #!/usr/bin/env bash
    
    ${pkgs.dunst}/bin/dunstify -u low -i clock -h string:x-dunst-stack-tag:timeNotifier -a "Time" "$(date --rfc-3339=seconds)"
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
    
    ${pkgs.dunst}/bin/dunstify -u low -i system -h string:x-dunst-stack-tag:workspaceNotifier -a "Workspaces" "Current: ''${currentWorkspace}" "''${notification}"
  '';

  battery = pkgs.writeShellScriptBin "battery-notifier" ''
    #!/usr/bin/env bash
    
    currentWorkspace=$(hyprctl activeworkspace | grep "workspace\sID" | awk '{print($3)}')
    displays=$(hyprctl workspaces | grep "workspace ID" | awk '{print($7)}' | sort -u)
    notification=""
    
    for display in $displays; do
      notification+="<b>$display<\b>\n"
    
      workspaces=$(hyprctl workspaces | grep "workspace\sID" | grep "\s''${display}" | awk '{print($3)}')
      for workspace in $workspaces; do
        if [ "$workspace" == "$currentWorkspace" ]; then
          notification+="  <u>$workspace<\u>\n"
        else
          notification+="  $workspace\n"
        fi
      done
    done
    
    ${pkgs.dunst}/bin/dunstify -u low -i system -h string:x-dunst-stack-tag:workspaceNotifier -a "Workspaces" "Current: ''${currentWorkspace}" "''${notification}"
  '';
}
