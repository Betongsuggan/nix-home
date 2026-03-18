{ pkgs, inputs, ... }:

{
  imports = [
    ../../modules/users
    inputs.stylix.homeModules.stylix
  ];

  home.username = "gamer";
  home.homeDirectory = "/home/gamer";
  home.stateVersion = "25.05";

  games = {
    enable = true;
    mangohud = {
      enable = true;
      detailedMode = true;
      controllerToggle = false;
      position = "top-left";
      fontSize = 22;
    };
    vkbasalt.enable = true;
    protonGE.enable = true;
    tools.enable = true;
  };

  general.enable = true;
  firefox.enable = true;
  fileManager = {
    enable = true;
    backend = "thunar";
  };

  communication.enable = true;
  localsend.enable = true;
  starship.enable = true;
  terminal = {
    enable = true;
    backend = "alacritty";
  };

  launcher = {
    enable = true;
    backend = "vicinae";
    vicinae = {
      extensions = with pkgs; [
        vicinae-wifi-commander
        vicinae-bluetooth
        vicinae-monitor
      ];
    };
  };

  controller = {
    enable = true;
    type = "ps5";
    mangohudToggle = {
      enable = true;
      buttons = [
        "square"
        "triangle"
      ]; # Press Square or Triangle to toggle
      autoStart = true;
    };
    rumble.enable = true;
  };

  # Enable Hyprland for gaming session
  # Steam Big Picture is managed by Sunshine when streaming clients connect
  hyprland.lockscreen.enable = false; # Gaming user doesn't need lockscreen
  hyprland.cmFsPassthrough = 1; # Always passthrough in fullscreen for HDR gaming
  hyprland.windowRules = [
    "fullscreenstate 1 2, class:^(steam)$" # Maximize internally (CM applies) but Steam thinks fullscreen
    "bordersize 0, class:^(steam)$"
    "rounding 0, class:^(steam)$"
  ];
  hyprland.workspaceRules = [
    "1, gapsin:0, gapsout:0" # No gaps on Steam workspace so maximize fills entire screen
  ];

  windowManager = {
    enable = true;
    backend = "hyprland";
    monitors = [
      "SUNSHINE,1920x1080@120,auto,1,vrr,1,bitdepth,10,cm,hdr,sdrbrightness,1.0,sdrsaturation,1.5"
      "DP-2,3440x1440@240,auto,1,vrr,1,bitdepth,10,cm,hdr,sdrbrightness,1.0,sdrsaturation,1.5"
      "HDMI-A-1,3840x2160@120,auto,2,vrr,1,bitdepth,10,cm,hdr,sdrbrightness,1.0,sdrsaturation,1.5"
      ",preferred,auto,1"
    ];

    # Virtual monitor for headless streaming
    virtualMonitors = [ "SUNSHINE" ];

    autostartApps = {
      steam = {
        command = "steam -gamepadui";
        workspace = 1;
      };
    };
  };

  shell = {
    enable = true;
    backend = "bash";
  };

  theme = {
    enable = true;
    wallpaper = ../../assets/wallpaper/zeal.jpg;
    cursor = {
      package = pkgs.banana-cursor;
      name = "Banana";
    };
  };

  git = {
    enable = true;
    userName = "Betongsuggan";
    userEmail = "rydback@gmail.com";
  };

  programs.console-mode = {
    enable = true;

    autoStart = false;

    gamescopeBin = "${pkgs.unstable.gamescope}/bin/gamescope";
    steamBin = "${pkgs.steam}/bin/steam";
    steamArgs = [ "-steamos3" ]; # Enable Steam Deck features (Bluetooth management, etc.)

    # Display settings auto-detected from EDID
    # Uncomment to override:
    # display = "card1-HDMI-A-1";
    # resolution = "2560x1440";
    # refreshRate = 144;
    # forceVrr = true;
    # forceHdr = true;

    environmentVariables = {
      RADV_PERFTEST = "gpl,ngg_culling,sam,rt";
      MESA_VK_WSI_PRESENT_MODE = "mailbox";
      AMD_VULKAN_ICD = "RADV";
      mesa_glthread = "true";
      VKD3D_CONFIG = "dxr11,dxr";
      STEAM_FRAME_FORCE_CLOSE = "1";
      STEAM_USE_DYNAMIC_VRS = "0";
      SDL_JOYSTICK_HIDAPI = "0";
      DXVK_ASYNC = "1";
      ENABLE_HDR_WSI = "1";
      DXVK_HDR = "1";
      RADV_RT_WAVE64 = "1";

      # Performance
      PROTON_FORCE_LARGE_ADDRESS_AWARE = "1";
      DXVK_LOG_LEVEL = "none";
      VKD3D_LOG_LEVEL = "none";
      STAGING_SHARED_MEMORY = "1";
      PROTON_ENABLE_WAYLAND = "1";

      PROTON_ENABLE_NVAPI = "1";
    };

    createDesktopEntry = true;
    desktopEntry = {
      name = "Gamescope Gaming Session";
      genericName = "Steam Big Picture (Gamescope)";
      comment = "Launch Steam Big Picture in Gamescope session";
      icon = "steam";
      categories = [
        "Game"
        "Application"
      ];
    };
  };

  home.packages =
    with pkgs;
    let
      gamescopeUnstable = unstable.gamescope;
    in
    [
      steam
      steam-run
      htop
      pulseaudio
      pavucontrol
      xdg-utils
      edid-decode
      gamescopeUnstable
    ];

  programs.bash = {
    enable = true;
    profileExtra = ''
      # Set XDG_VTNR if not already set
      if [[ -z "$XDG_VTNR" ]]; then
        TTY=$(tty)
        case "$TTY" in
          /dev/tty[0-9]*)
            export XDG_VTNR="''${TTY##*/tty}"
            ;;
        esac
      fi

      # Launch Hyprland on TTY1 (if not already in a graphical session)
      # Hyprland auto-starts Steam Big Picture and Sunshine
      if [[ "$XDG_VTNR" = "1" && -z "$WAYLAND_DISPLAY" ]]; then
        exec Hyprland
      fi
    '';
  };

  home.sessionVariables = {
    # AMD GPU - RDNA4 optimized
    RADV_PERFTEST = "gpl,ngg_culling,sam,rt";
    MESA_VK_WSI_PRESENT_MODE = "mailbox";
    AMD_VULKAN_ICD = "RADV";
    mesa_glthread = "true";
    VKD3D_CONFIG = "dxr11,dxr";

    # Steam
    STEAM_FRAME_FORCE_CLOSE = "1";
    STEAM_USE_DYNAMIC_VRS = "0";

    # Proton/Wine
    DXVK_ASYNC = "1";
    PROTON_ENABLE_NVAPI = "1";

    # Controller
    SDL_JOYSTICK_HIDAPI = "0";
    SDL_VIDEODRIVER = "wayland,x11";

    # HDR
    ENABLE_HDR_WSI = "1";
    DXVK_HDR = "1";

    # RDNA4 specific
    RADV_RT_WAVE64 = "1";

    # Performance
    PROTON_FORCE_LARGE_ADDRESS_AWARE = "1";
    DXVK_LOG_LEVEL = "none";
    VKD3D_LOG_LEVEL = "none";
    STAGING_SHARED_MEMORY = "1";
    PROTON_ENABLE_WAYLAND = "1";
  };

  programs.home-manager.enable = true;
}
