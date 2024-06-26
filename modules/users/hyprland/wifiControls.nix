{ pkgs, ... }:
let
  wifiControl = pkgs.writeShellScriptBin "wifi-control" ''
    #!/usr/bin/env bash
    
    # Get a list of available wifi connections and morph it into a nice-looking list
    wifi_list=$(nmcli --fields "SECURITY,SSID" device wifi list | sed 1d | sed 's/  */ /g' | sed -E "s/WPA*.?\S/ /g" | sed "s/^--/ /g" | sed "s/  //g" | sed "/--/d")
    
    connected=$(nmcli -fields WIFI g)
    if [[ "$connected" =~ "enabled" ]]; then
    	toggle="󰖪  Disable Wi-Fi"
    elif [[ "$connected" =~ "disabled" ]]; then
    	toggle="󰖩  Enable Wi-Fi"
    fi

    rescan="󰖩  Rescan Wi-Fi"
    
    # Use Wofi to select wifi network
    chosen_network=$(echo -e "$toggle\n$rescan\n$wifi_list" | uniq -u | wofi --dmenu --prompt "Wi-Fi SSID: " )
    # Get name of connection
    read -r chosen_id <<< "''${chosen_network:3}"
    
    if [ "$chosen_network" = "" ]; then
    	exit
    elif [ "$chosen_network" = "󰖩  Enable Wi-Fi" ]; then
    	nmcli radio wifi on
    elif [ "$chosen_network" = "󰖪  Disable Wi-Fi" ]; then
    	nmcli radio wifi off
    elif [ "$chosen_network" = "󰖪  Rescan Wi-Fi" ]; then
    	nmcli dev wifi list --rescan yes
    else
    	# Message to show when connection is activated successfully
      	success_message="Connected to \"<b>$chosen_id</b>\"."
    	# Get saved connections
    	saved_connections=$(nmcli -g NAME connection)
    	if [[ $(echo "$saved_connections" | grep -w "$chosen_id") = "$chosen_id" ]]; then
    		nmcli connection up id "$chosen_id" | grep "successfully" && dunstify "Connection Established" "$success_message"
    	else
    		if [[ "$chosen_network" =~ "" ]]; then
    			wifi_password=$(wofi --dmenu --password --prompt "Password: " )
    		fi
    		nmcli device wifi connect "$chosen_id" password "$wifi_password" | grep "successfully" && dunstify -a "Wi-Fi connection" -i "$success_message"
        fi
    fi
  '';
in
wifiControl
