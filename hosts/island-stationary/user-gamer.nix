{ pkgs, inputs, ... }:

{
  imports = [
    ../../modules/user.nix
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
  chromium.enable = true;
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
  hyprland.lockscreen.enable = false; # Gaming user doesn't need lockscreen
  hyprland.windowRules = [
    "fullscreenstate 1 2, class:^(steam)$"
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
      ",preferred,auto,1"
    ];

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
    steamArgs = [ "-steamos3" ];

    environmentVariables = {
      VKD3D_CONFIG = "dxr11,dxr";
      STEAM_FRAME_FORCE_CLOSE = "1";
      STEAM_USE_DYNAMIC_VRS = "0";
      SDL_JOYSTICK_HIDAPI = "0";
      DXVK_ASYNC = "1";

      # NVIDIA shader caching
      __GL_SHADER_DISK_CACHE = "1";
      __GL_SHADER_DISK_CACHE_SKIP_CLEANUP = "1";

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
      if [[ "$XDG_VTNR" = "1" && -z "$WAYLAND_DISPLAY" ]]; then
        exec Hyprland
      fi
    '';
  };

  home.sessionVariables = {
    # NVIDIA shader caching
    __GL_SHADER_DISK_CACHE = "1";
    __GL_SHADER_DISK_CACHE_SKIP_CLEANUP = "1";

    # Vulkan
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

    # Performance
    PROTON_FORCE_LARGE_ADDRESS_AWARE = "1";
    DXVK_LOG_LEVEL = "none";
    VKD3D_LOG_LEVEL = "none";
    STAGING_SHARED_MEMORY = "1";
    PROTON_ENABLE_WAYLAND = "1";
  };

  programs.home-manager.enable = true;
}
