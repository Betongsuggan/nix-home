{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.my.power-management;

  # Samples the battery/AC sysfs nodes to a log that is fdatasync'd after every
  # write. Buffered writers (journald included) lose the final seconds on a hard
  # power cut, which is exactly the window that tells a failing battery pack
  # (present=0, or voltage_now sagging under load) apart from a firmware fault
  # (telemetry normal right up to the cut).
  powerTelemetry = pkgs.writeShellApplication {
    name = "power-telemetry";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      log=/var/log/power-telemetry.log
      # First system battery and mains supply, whatever the firmware names them
      # (BAT0/BAT1, AC/ACAD/ADP1)
      supply() {
        for s in /sys/class/power_supply/*; do
          # scope=Device marks peripherals (a wireless mouse's battery)
          if [ "$(cat "$s/type" 2>/dev/null)" = "$1" ] \
             && [ "$(cat "$s/scope" 2>/dev/null)" != "Device" ]; then
            echo "$s"; return
          fi
        done
        echo /nonexistent
      }
      bat=$(supply Battery)
      ac=$(supply Mains)

      val() {
        if [ -r "$1" ]; then cat "$1" 2>/dev/null || echo "?"; else echo "?"; fi
      }

      tctl() {
        for h in /sys/class/hwmon/hwmon*; do
          if [ -r "$h/name" ] && [ "$(cat "$h/name")" = "k10temp" ] \
             && [ -r "$h/temp1_input" ]; then
            cat "$h/temp1_input"
            return
          fi
        done
        echo "?"
      }

      while true; do
        printf '%s present=%s status=%s ac=%s volt_uV=%s power_uW=%s energy_uWh=%s cap=%s tctl_mC=%s\n' \
          "$(date -Is)" \
          "$(val "$bat/present")" \
          "$(val "$bat/status")" \
          "$(val "$ac/online")" \
          "$(val "$bat/voltage_now")" \
          "$(val "$bat/power_now")" \
          "$(val "$bat/energy_now")" \
          "$(val "$bat/capacity")" \
          "$(tctl)" >> "$log"
        sync --data "$log"
        sleep ${toString cfg.forensics.interval}
      done
    '';
  };
in
{
  options.my.power-management = {
    enable = mkEnableOption "Enable power management";

    cpuVendor = mkOption {
      type = types.nullOr (
        types.enum [
          "amd"
          "intel"
        ]
      );
      default = null;
      description = ''
        CPU vendor for vendor-specific power settings.
        Set to "amd" for AMD P-State and platform profile settings.
        Set to "intel" for Intel-specific settings.
        Set to null to skip vendor-specific CPU settings.
      '';
      example = "amd";
    };

    gpuVendor = mkOption {
      type = types.nullOr (
        types.enum [
          "amd"
          "intel"
          "nvidia"
        ]
      );
      default = null;
      description = ''
        GPU vendor for vendor-specific power settings.
        Set to "amd" for AMD GPU power management settings.
        Set to null to skip vendor-specific GPU settings.
      '';
      example = "amd";
    };

    powerModes = {
      ac = mkOption {
        description = ''
          CPU scaling governor on AC. With amd_pstate/intel_pstate active,
          "powersave" lets the energy-performance preference (balance_performance
          on AC) steer; "performance" pins the preference to performance.
        '';
        type = types.str;
        default = "powersave";
      };

      battery = mkOption {
        description = "Default system power governor on battery";
        type = types.str;
        default = "powersave";
      };
    };

    platformProfiles = {
      ac = mkOption {
        description = ''
          ACPI platform profile on AC. Lowering this to "low-power" caps the
          firmware power budget, which reduces the transient draw a weak or
          failing battery has to absorb on top of the charger.
        '';
        type = types.str;
        default = "balanced";
      };

      battery = mkOption {
        description = "ACPI platform profile on battery";
        type = types.str;
        default = "low-power";
      };
    };

    amdgpuPerfLevel = {
      ac = mkOption {
        description = ''
          amdgpu DPM performance level on AC. "low" pins the GPU to its lowest
          clocks, trading throughput for a much smaller peak draw.
        '';
        type = types.str;
        default = "auto";
      };

      battery = mkOption {
        description = "amdgpu DPM performance level on battery (\"low\" pins the lowest clocks)";
        type = types.str;
        default = "auto";
      };
    };

    amdgpuAbmLevel = {
      ac = mkOption {
        description = "amdgpu Adaptive Backlight Management on AC (0 = off)";
        type = types.ints.between 0 4;
        default = 0;
      };
      battery = mkOption {
        description = ''
          amdgpu Adaptive Backlight Management on battery (0-4): lowers the
          panel backlight and compensates contrast; the panel is usually the
          largest single consumer on battery.
        '';
        type = types.ints.between 0 4;
        default = 3;
      };
    };

    forensics = {
      enable = mkEnableOption ''
        power-loss forensics: sample battery/AC telemetry to a disk-synced log
        and make kernel oopses reboot so they leave a pstore record
      '';

      interval = mkOption {
        description = "Seconds between telemetry samples";
        type = types.int;
        default = 5;
      };
    };
  };

  config = mkIf cfg.enable {
    # The CPU governor is owned by TLP (powerModes below); a boot-time
    # powerManagement.cpuFreqGovernor would only race it.

    services.upower.enable = true;

    # Intel thermal daemon: keeps the package within limits before firmware throttling kicks in
    services.thermald.enable = mkIf (cfg.cpuVendor == "intel") (mkDefault true);

    # Ryzen power/boost tuning CLI
    environment.systemPackages = optional (cfg.cpuVendor == "amd") pkgs.ryzenadj;

    # Lid close behavior, gated on external displays rather than power source:
    # logind counts the system as "docked" when a docking station is attached
    # OR more than one display is connected, so lid close with an external
    # monitor stays awake while lid close on the panel alone suspends (on AC
    # and battery alike). Inactivity suspend is unaffected (hypridle).
    # Note: Hyprland handles locking via bindl on lid switch events
    services.logind.settings.Login = {
      HandleLidSwitch = "suspend"; # No external display: suspend
      HandleLidSwitchExternalPower = "suspend"; # Same on AC
      HandleLidSwitchDocked = "ignore"; # External display connected: stay awake
    };

    services.tlp = {
      enable = true;
      settings = mkMerge [
        # Common settings (apply to all systems)
        {
          # CPU Scaling
          CPU_SCALING_GOVERNOR_ON_AC = cfg.powerModes.ac;
          CPU_SCALING_GOVERNOR_ON_BAT = cfg.powerModes.battery;

          # Disable CPU boost on battery (significant power savings)
          CPU_BOOST_ON_AC = 1;
          CPU_BOOST_ON_BAT = 0;

          # PCIe power management
          PCIE_ASPM_ON_AC = "default";
          PCIE_ASPM_ON_BAT = "powersupersave";

          # Runtime PM for PCI devices
          RUNTIME_PM_ON_AC = "auto";
          RUNTIME_PM_ON_BAT = "auto";

          # USB autosuspend
          USB_AUTOSUSPEND = 1;

          # SATA/NVMe power management
          SATA_LINKPWR_ON_AC = "med_power_with_dipm";
          SATA_LINKPWR_ON_BAT = "min_power";
          AHCI_RUNTIME_PM_ON_AC = "auto";
          AHCI_RUNTIME_PM_ON_BAT = "auto";

          # WiFi power saving
          WIFI_PWR_ON_AC = "off";
          WIFI_PWR_ON_BAT = "on";

          # Sound power saving
          SOUND_POWER_SAVE_ON_AC = 0;
          SOUND_POWER_SAVE_ON_BAT = 1;
          SOUND_POWER_SAVE_CONTROLLER = "Y";
        }

        # AMD CPU-specific settings
        (mkIf (cfg.cpuVendor == "amd") {
          # AMD P-State Energy Policy
          CPU_ENERGY_PERF_POLICY_ON_AC = "balance_performance";
          CPU_ENERGY_PERF_POLICY_ON_BAT = "power";

          # Platform profile (AMD laptops)
          PLATFORM_PROFILE_ON_AC = cfg.platformProfiles.ac;
          PLATFORM_PROFILE_ON_BAT = cfg.platformProfiles.battery;
        })

        # Intel CPU-specific settings
        (mkIf (cfg.cpuVendor == "intel") {
          # Intel P-State/HWP Energy Policy
          CPU_ENERGY_PERF_POLICY_ON_AC = "balance_performance";
          CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
        })

        # AMD GPU-specific settings
        (mkIf (cfg.gpuVendor == "amd") {
          # TLP's names for amdgpu (the AMDGPU_*DPM* keys used before don't
          # exist in TLP and were silently ignored)
          RADEON_DPM_PERF_LEVEL_ON_AC = cfg.amdgpuPerfLevel.ac;
          RADEON_DPM_PERF_LEVEL_ON_BAT = cfg.amdgpuPerfLevel.battery;
          AMDGPU_ABM_LEVEL_ON_AC = cfg.amdgpuAbmLevel.ac;
          AMDGPU_ABM_LEVEL_ON_BAT = cfg.amdgpuAbmLevel.battery;
        })
      ];
    };

    # Forensics for unexplained hard power-offs: a hard cut leaves no trace in
    # the journal, so sample power state continuously and sync each line to
    # disk, and make any kernel oops panic so it lands in pstore instead of
    # limping on and dying unrecorded.
    boot.kernel.sysctl = mkIf cfg.forensics.enable {
      "kernel.panic" = 10;
      "kernel.panic_on_oops" = 1;
    };

    systemd.services.power-telemetry = mkIf cfg.forensics.enable {
      description = "Power-loss forensics telemetry";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = getExe powerTelemetry;
        Restart = "always";
        RestartSec = 5;
        Nice = 10;
      };
    };

    services.logrotate.settings.power-telemetry = mkIf cfg.forensics.enable {
      files = "/var/log/power-telemetry.log";
      frequency = "daily";
      rotate = 14;
      compress = true;
      missingok = true;
      notifempty = true;
    };
  };
}
