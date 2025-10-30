{ pkgs, inputs, ... }:

{
  imports = [ ../../modules/users inputs.stylix.homeModules.stylix ];

  home.username = "gamer";
  home.homeDirectory = "/home/gamer";
  home.stateVersion = "25.05";

  # Enable gaming setup with enhanced MangoHud
  games = {
    enable = true;
    mangohud = {
      enable = true;
      detailedMode = true;
      controllerToggle = false; # Now handled by controller module
      position = "top-left";
      fontSize = 22;
    };
  };

  battery-monitor.enable = true;

  launcher = {
    enable = true;
    backend = "walker";
  };

  controller = {
    enable = true;
    type = "ps5";
    mangohudToggle = {
      enable = true;
      buttons = [ "square" "triangle" ]; # Press Square or Triangle to toggle
      autoStart = true;
    };
    rumble.enable = true;
  };

  windowManager.enable = true;
  windowManager.type = "hyprland";

  shell.enable = true;
  shell.defaultShell = "bash";
  theme = {
    enable = true;
    wallpaper = ../../assets/wallpaper/zeal.jpg;
    cursor = {
      package = pkgs.banana-cursor;
      name = "Banana";
    };
  };

  # Create gamescope session launcher script
  home.packages = with pkgs; [
    steam
    steam-run
    htop
    pulseaudio
    pavucontrol
    xdg-utils

    # Gamescope session launcher
    (writeShellScriptBin "start-gamescope-session" ''
      # Ensure environment variables are set
      export STEAM_FORCE_DESKTOPUI_SCALING=1
      export LIBINPUT_QUIRKS_DIR=/usr/share/libinput
      export XDG_SESSION_TYPE=''${XDG_SESSION_TYPE:-tty}

      # Get native resolution from connected display
      # Scan for all connected displays and let user choose
      RESOLUTION="1920x1080"  # Default fallback

      # Build array of connected displays
      declare -a DISPLAYS
      declare -a RESOLUTIONS
      INDEX=0

      for status_file in /sys/class/drm/card*/card*-*/status; do
        if [ -f "$status_file" ]; then
          status=$(${coreutils}/bin/cat "$status_file" 2>/dev/null)
          # Match only "connected", not "disconnected"
          if [ "$status" = "connected" ]; then
            connector_dir=$(${coreutils}/bin/dirname "$status_file")
            connector_name=$(${coreutils}/bin/basename "$connector_dir")
            modes_file="$connector_dir/modes"
            if [ -f "$modes_file" ]; then
              resolution=$(${coreutils}/bin/cat "$modes_file" 2>/dev/null | ${coreutils}/bin/head -1 || echo "1920x1080")
              DISPLAYS[$INDEX]="$connector_name"
              RESOLUTIONS[$INDEX]="$resolution"
              INDEX=$((INDEX + 1))
            fi
          fi
        fi
      done

      # If multiple displays found, prompt user to choose
      if [ ''${#DISPLAYS[@]} -gt 1 ]; then
        echo ""
        echo "=== Gaming Display Selection ==="
        echo ""
        for i in "''${!DISPLAYS[@]}"; do
          echo "  [$((i+1))] ''${DISPLAYS[$i]} - ''${RESOLUTIONS[$i]}"
        done
        echo ""
        echo -n "Select display (1-''${#DISPLAYS[@]}): "
        read -r choice

        # Validate input
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "''${#DISPLAYS[@]}" ]; then
          RESOLUTION="''${RESOLUTIONS[$((choice-1))]}"
          echo "Using ''${DISPLAYS[$((choice-1))]} at $RESOLUTION"
        else
          echo "Invalid choice, using first display: ''${DISPLAYS[0]} at ''${RESOLUTIONS[0]}"
          RESOLUTION="''${RESOLUTIONS[0]}"
        fi
        echo ""
        ${coreutils}/bin/sleep 2
      elif [ ''${#DISPLAYS[@]} -eq 1 ]; then
        # Single display, use it automatically
        RESOLUTION="''${RESOLUTIONS[0]}"
        echo "Detected display: ''${DISPLAYS[0]} at $RESOLUTION"
        ${coreutils}/bin/sleep 1
      else
        # No displays found, use fallback
        echo "No connected displays detected, using fallback: 1920x1080"
        ${coreutils}/bin/sleep 1
      fi

      WIDTH=$(echo $RESOLUTION | ${coreutils}/bin/cut -d'x' -f1)
      HEIGHT=$(echo $RESOLUTION | ${coreutils}/bin/cut -d'x' -f2)

      # Fallback to 1920x1080 if detection fails
      WIDTH=''${WIDTH:-1920}
      HEIGHT=''${HEIGHT:-1080}

      # Detect highest refresh rate for the connected display
      # Try common high refresh rates, fallback to 60
      for REFRESH_RATE in 240 165 144 120 100 75 60; do
        if ${kmod}/bin/modinfo amdgpu > /dev/null 2>&1; then
          # For AMD GPUs, assume high refresh rate support
          if [ "$REFRESH_RATE" = "240" ] || [ "$REFRESH_RATE" = "165" ] || [ "$REFRESH_RATE" = "144" ]; then
            break
          fi
        else
          # Conservative fallback
          if [ "$REFRESH_RATE" = "60" ]; then
            break
          fi
        fi
      done

      exec ${gamescope}/bin/gamescope -W $WIDTH -H $HEIGHT -r $REFRESH_RATE --hdr-enabled -f -e -- ${steam}/bin/steam -bigpicture
    '')
  ];

  programs.bash = {
    enable = true;
    profileExtra = ''
      # Auto-start Steam Big Picture Mode if not already running and on main console
      if [[ -z "$DISPLAY" && "$XDG_VTNR" = "1" ]]; then
        exec start-gamescope-session
      fi
    '';
  };

  # Desktop file for launching gamescope session from desktop environment
  xdg.desktopEntries.gamescope-session = {
    name = "Gamescope Gaming Session";
    genericName = "Steam Big Picture (Gamescope)";
    comment = "Launch Steam Big Picture in Gamescope session";
    exec = "start-gamescope-session";
    icon = "steam";
    terminal = false;
    categories = [ "Game" "Application" ];
    type = "Application";
  };

  home.sessionVariables = {
    # MangoHud variables are now handled by the games module
    # DXVK_HUD = "fps";  # Might conflict with MangoHud
    # AMD GPU optimizations for gamescope
    RADV_PERFTEST = "gpl";
    MESA_VK_WSI_PRESENT_MODE = "mailbox";
    # Controller and overlay fixes
    STEAM_USE_DYNAMIC_VRS = "0";
    # Force SDL to use evdev backend for better compatibility
    SDL_JOYSTICK_HIDAPI = "0";
    #STEAM_FRAME_FORCE_CLOSE = "1";
    # Enable FSR for compatible games
    #WINE_FULLSCREEN_FSR = "1";
    # Optimize Steam overlay - keep disabled for AMD
    #STEAM_DISABLE_OVERLAY_DWM = "1";
  };

  programs.home-manager.enable = true;
}

