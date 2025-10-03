{ config, lib, pkgs, ... }:

with lib;

{
  options.games = {
    enable = mkEnableOption "Enable gaming setup";

    steamBigPicture = mkOption {
      type = types.bool;
      default = false;
      description = "Auto-start Steam in Big Picture mode";
    };

    mangohud = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable MangoHud overlay";
      };

      detailedMode = mkOption {
        type = types.bool;
        default = true;
        description = "Show detailed system information in MangoHud";
      };

      controllerToggle = mkOption {
        type = types.bool;
        default = true;
        description = "Enable controller-based MangoHud toggle via AntiMicroX";
      };

      position = mkOption {
        type = types.enum [ "top-left" "top-right" "bottom-left" "bottom-right" "top-center" "bottom-center" ];
        default = "top-left";
        description = "MangoHud overlay position";
      };

      fontSize = mkOption {
        type = types.int;
        default = 24;
        description = "MangoHud font size";
      };
    };
  };

  config = mkIf config.games.enable {
    programs.mangohud = mkIf config.games.mangohud.enable {
      enable = true;
      enableSessionWide = true;
      settings = {
        # Performance metrics
        fps = true;
        frametime = true;
        frame_timing = true;
        
        # GPU information
        gpu_stats = true;
        gpu_temp = true;
        gpu_junction_temp = true;
        gpu_mem_temp = true;
        gpu_power = true;
        gpu_fan = true;
        gpu_name = config.games.mangohud.detailedMode;
        
        # CPU information
        cpu_stats = true;
        cpu_temp = true;
        cpu_power = true;
        cpu_mhz = config.games.mangohud.detailedMode;
        core_load = config.games.mangohud.detailedMode;
        
        # Memory information
        vram = true;
        ram = true;
        swap = config.games.mangohud.detailedMode;
        procmem = config.games.mangohud.detailedMode;
        
        # System information
        throttling_status = true;
        fsr = true;
        gamemode = config.games.mangohud.detailedMode;
        vulkan_driver = config.games.mangohud.detailedMode;
        engine_version = config.games.mangohud.detailedMode;
        wine = config.games.mangohud.detailedMode;
        arch = config.games.mangohud.detailedMode;
        resolution = config.games.mangohud.detailedMode;
        display_server = config.games.mangohud.detailedMode;
        
        # Time and system status
        time = config.games.mangohud.detailedMode;
        time_format = "%H:%M:%S";
        version = config.games.mangohud.detailedMode;
        
        # Network and IO (for detailed mode)
        network = mkIf config.games.mangohud.detailedMode true;
        io_read = mkIf config.games.mangohud.detailedMode true;
        io_write = mkIf config.games.mangohud.detailedMode true;
        
        # Visual settings
        position = config.games.mangohud.position;
        font_size = config.games.mangohud.fontSize;
        text_outline = true;
        text_outline_thickness = 1.5;
        round_corners = 8;
        
        # Controller toggle keybind (F9 key for AntiMicroX to trigger)
        toggle_hud = "F9";
        
        # Start hidden by default (toggle with controller)
        no_display = true;
        
        # Color scheme
        text_color = "FFFFFF";
        gpu_color = "2E9762";
        cpu_color = "2E97CB";
        vram_color = "AD64C1";
        ram_color = "C26693";
        frametime_color = "00FF00";
        background_color = "020202";
        background_alpha = 0.8;
      };
    };

    home.packages = with pkgs; [
      chiaki
      discord
      #unstable.emulationstation-de
      libretro.snes9x
      evtest
      gamescope
      gamemode
      lutris
      # Standard RetroArch is still included if you want to use it separately
      #retroarch
      steam
      steam-run
      steamcontroller
    ] ++ lib.optionals config.games.mangohud.controllerToggle [
      antimicrox
    ];

    # Steam Big Picture autostart service
    systemd.user.services.steam-bigpicture = mkIf config.games.steamBigPicture {
      Unit = {
        Description = "Steam Big Picture Mode";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Service = {
        Type = "simple";
        ExecStart = "${pkgs.steam}/bin/steam -bigpicture";
        Restart = "on-failure";
        RestartSec = "5s";
        Environment = "DISPLAY=:0";
      };

      Install = { WantedBy = [ "graphical-session.target" ]; };
    };

    # AntiMicroX controller profile for MangoHud toggle
    xdg.configFile."antimicrox/gamepadprofiles/mangohud-toggle.gamecontroller.amgp" = mkIf config.games.mangohud.controllerToggle {
      text = ''
        <?xml version="1.0" encoding="UTF-8"?>
        <gamecontroller configname="MangoHud Toggle Profile" configversion="3.5" appversion="3.5.1">
            <names>
                <controlstick1>LS</controlstick1>
                <controlstick2>RS</controlstick2>
            </names>
            <sets>
                <set index="1">
                    <!-- Map Back/Select + Y button to F9 (MangoHud toggle) -->
                    <button index="7">
                        <buttonname>Back/Select</buttonname>
                        <modifier>true</modifier>
                    </button>
                    <button index="4">
                        <buttonname>Y</buttonname>
                        <slots>
                            <slot>
                                <code>67</code>
                                <mode>keyboard</mode>
                            </slot>
                        </slots>
                        <modifierslots>
                            <slot>
                                <code>67</code>
                                <mode>keyboard</mode>
                            </slot>
                        </modifierslots>
                    </button>
                    <!-- Alternative single button mapping for easier access -->
                    <button index="10">
                        <buttonname>Back/Select + Start</buttonname>
                        <slots>
                            <slot>
                                <code>67</code>
                                <mode>keyboard</mode>
                            </slot>
                        </slots>
                    </button>
                </set>
            </sets>
        </gamecontroller>
      '';
    };

    # Auto-start AntiMicroX with the MangoHud profile
    systemd.user.services.antimicrox = mkIf config.games.mangohud.controllerToggle {
      Unit = {
        Description = "AntiMicroX Controller Mapping";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Service = {
        Type = "simple";
        ExecStart = "${pkgs.antimicrox}/bin/antimicrox --hidden --profile %h/.config/antimicrox/gamepadprofiles/mangohud-toggle.gamecontroller.amgp";
        Restart = "on-failure";
        RestartSec = "5s";
        Environment = [
          "DISPLAY=:0"
          "XDG_RUNTIME_DIR=%h/.runtime"
        ];
      };

      Install = { WantedBy = [ "graphical-session.target" ]; };
    };

    # unfreePackages moved to system level configuration
  };
}
