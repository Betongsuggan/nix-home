{ pkgs, inputs, ... }:

{
  imports = [ ./session.nix ];

  home.stateVersion = "25.05";

  my.games = {
    enable = true;
    mangohud = {
      enable = true;
      detailedMode = true;
      position = "top-left";
      fontSize = 22;
    };
    vkbasalt.enable = true;
    protonGE.enable = true;
    tools.enable = true;
    emulators = {
      enable = true;
      # Per-ROM Steam tiles for all emulated systems (SNES/NES/GB/GBC/GBA/N64/
      # PSX/MegaDrive/MasterSystem from the RetroArch cores, plus Switch),
      # written by emulation-apply-shortcuts. See modules/games/SPEC.md.
      steamShortcuts = {
        enable = true;
        # SteamGridDB key (vault common.yaml) — used to fetch grid artwork
        # for the generated Steam tiles.
        artwork.apiKeyFile = "/run/secrets/steamgriddb-api-key";
      };
      # Nintendo Switch via Ryubing (Ryujinx fork). Keys/firmware are pulled
      # from the controller bios/switch share; see modules/games/SPEC.md.
      switch.enable = true;
    };
    steamIntegration.enable = true;
  };

  # Re-enabled for Switch save sync: Ryujinx writes saves under
  # ~/emulation/saves/switch, which Syncthing mirrors to the controller.
  # (ROM/BIOS mounts come from the emulation-mounts system module, not this.)
  my.emulation-client = {
    enable = true;
    # Controller runs tailnetOnly (Samba/Syncthing closed on the LAN), so the
    # share address must be the tailnet FQDN — the old LAN IP was dead.
    server.address = inputs.self.lib.tailnet.fqdn "controller";
  };

  my.localsend.enable = true;

  my.controller = {
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
  };

  # Enable Hyprland for gaming session
  # Steam Big Picture is managed by Sunshine when streaming clients connect
  my.window-manager.hyprland.lockscreen.enable = false; # Gaming user doesn't need lockscreen
  my.window-manager.hyprland.cmFsPassthrough = 1; # Always passthrough in fullscreen for HDR gaming
  # No window rules: Hyprland 0.55's new `windowrule` parser rejects the old
  # `class:^()$` matcher, and `windowrulev2` (still functional) emits a
  # persistent on-screen deprecation warning. The old Steam tweaks are obsolete
  # on 0.55 — Big Picture self-fullscreens and HDR/CM fullscreen passthrough is
  # automatic now (cm_auto_hdr replaced cm_fs_passthrough). Ryujinx is brought
  # fullscreen by its per-game launcher (hyprctl dispatch fullscreen 0).
  my.window-manager.hyprland.windowRules = [ ];
  my.window-manager.hyprland.workspaceRules = [
    "1, gapsin:0, gapsout:0" # No gaps on Steam workspace so maximize fills entire screen
  ];

  # The PC monitor and TV come from session.nix; the gamer session adds the
  # SUNSHINE streaming output. It always exists (Sunshine's /launch fails
  # without it), but sits far from the others so the cursor can't reach it,
  # and only holds the streaming workspace; prepare-streaming-session sets it
  # to the client's resolution and turns the physical outputs off.
  my.window-manager = {
    monitors = {
      SUNSHINE = {
        mode = {
          width = 1920;
          height = 1080;
          refresh = 120;
        };
        position = {
          x = 20000;
          y = 0;
        };
        vrr = true;
        bitdepth = 10;
        hdr = true;
        sdrBrightness = 1.0;
        sdrSaturation = 1.5;
      };
    };
    workspaceBindings = [
      {
        workspace = 10;
        monitor = "SUNSHINE";
        default = true;
      }
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

  programs.console-mode = {
    enable = true;

    autoStart = false;

    gamescopeBin = "${pkgs.unstable.gamescope}/bin/gamescope";
    # steamBin unset: `steam` from PATH is the programs.steam wrapper, which
    # carries the Proton-GE compat-tool paths (a raw pkgs.steam would not)
    steamArgs = [ "-steamos3" ]; # Enable Steam Deck features (Bluetooth management, etc.)

    # Display settings auto-detected from EDID
    # Uncomment to override:
    # display = "card1-HDMI-A-1";
    # resolution = "2560x1440";
    # refreshRate = 144;
    # forceVrr = true;
    # forceHdr = true;

    environmentVariables = {
      MESA_VK_WSI_PRESENT_MODE = "mailbox";
      STEAM_FRAME_FORCE_CLOSE = "1";
      STEAM_USE_DYNAMIC_VRS = "0";
      SDL_JOYSTICK_HIDAPI = "0";
      DXVK_ASYNC = "1";
      ENABLE_HDR_WSI = "1";
      DXVK_HDR = "1";

      # Performance
      PROTON_FORCE_LARGE_ADDRESS_AWARE = "1";
      DXVK_LOG_LEVEL = "none";
      VKD3D_LOG_LEVEL = "none";
      STAGING_SHARED_MEMORY = "1";
      # No PROTON_ENABLE_WAYLAND: Wine's Wayland driver renders CEF launchers
      # (Battle.net) as a white, flickering window under GE-Proton 11; opt in
      # per game with `PROTON_ENABLE_WAYLAND=1 %command%`. No
      # PROTON_ENABLE_NVAPI: this is an AMD GPU, NVAPI only makes games probe
      # for a missing NVIDIA card.
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
      # `steam` comes from programs.steam (games module, NixOS half): a copy
      # here would shadow its wrapper, which carries the Proton-GE paths
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
        # start-hyprland (Hyprland >= 0.53): a watchdog that relaunches
        # Hyprland in safe mode after a crash instead of dropping the
        # autologin session to a bare TTY
        exec start-hyprland
      fi
    '';
  };

  home.sessionVariables = {
    # AMD GPU — RADV/vkd3d defaults are correct on modern Mesa; no tuning vars
    MESA_VK_WSI_PRESENT_MODE = "mailbox";

    # Steam
    STEAM_FRAME_FORCE_CLOSE = "1";
    STEAM_USE_DYNAMIC_VRS = "0";

    # Proton/Wine (no PROTON_ENABLE_NVAPI on AMD, see console-mode above)
    DXVK_ASYNC = "1";

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
    # PROTON_ENABLE_WAYLAND deliberately unset, see console-mode above
  };

}
