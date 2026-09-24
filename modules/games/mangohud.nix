{ config, lib, ... }:
with lib;

let
  cfg = config.my.games;
in
{
  config = mkIf cfg.enable {
    programs.mangohud = mkIf cfg.mangohud.enable {
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
        gpu_core_clock = true;
        gpu_mem_clock = true;
        gpu_name = cfg.mangohud.detailedMode;
        gpu_voltage = true;

        # CPU information
        cpu_stats = true;
        cpu_temp = true;
        cpu_power = true;
        cpu_mhz = cfg.mangohud.detailedMode;
        core_load = cfg.mangohud.detailedMode;

        # Memory information
        vram = true;
        ram = true;
        swap = cfg.mangohud.detailedMode;
        procmem = cfg.mangohud.detailedMode;

        # Gaming features
        fsr = true;
        hdr = true;
        refresh_rate = true;
        show_fps_limit = true;
        present_mode = true;
        gamemode = true;
        vkbasalt = cfg.vkbasalt.enable;
        winesync = true;

        # System information
        throttling_status = true;
        vulkan_driver = true;
        engine_version = cfg.mangohud.detailedMode;
        wine = true;
        resolution = true;
        arch = cfg.mangohud.detailedMode;
        display_server = cfg.mangohud.detailedMode;

        # Controller battery
        device_battery = "gamepad";
        device_battery_icon = true;

        # Time and system status
        time = true;
        time_format = "%H:%M:%S";
        version = cfg.mangohud.detailedMode;

        # Network and IO (for detailed mode)
        network = mkIf cfg.mangohud.detailedMode true;
        io_read = mkIf cfg.mangohud.detailedMode true;
        io_write = mkIf cfg.mangohud.detailedMode true;

        # Visual settings
        position = cfg.mangohud.position;
        font_size = cfg.mangohud.fontSize;
        text_outline = true;
        text_outline_thickness = 1.5;
        round_corners = 8;

        # Toggle keybind (Shift+F9 avoids game F-key conflicts)
        toggle_hud = "Shift_R+F9";

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
  };
}
