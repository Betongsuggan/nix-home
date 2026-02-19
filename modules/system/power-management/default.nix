{ config, lib, pkgs, ... }:
with lib;

{
  options.power-management = {
    enable = mkEnableOption "Enable power management";

    powerModes = {
      ac = mkOption {
        description = "Default system power governor on AC";
        type = types.str;
        default = "performance";
      };

      battery = mkOption {
        description = "Default system power governor on battery";
        type = types.str;
        default = "powersave";
      };
    };
  };
  config = mkIf config.power-management.enable {
    # Prioritize performance over efficiency
    powerManagement.cpuFreqGovernor = "powersave";

    services.upower.enable = true;

    services.tlp = {
      enable = true;
      settings = {
        # CPU Scaling
        CPU_SCALING_GOVERNOR_ON_AC = config.power-management.powerModes.ac;
        CPU_SCALING_GOVERNOR_ON_BAT = config.power-management.powerModes.battery;

        # AMD P-State Energy Policy
        CPU_ENERGY_PERF_POLICY_ON_AC = "balance_performance";
        CPU_ENERGY_PERF_POLICY_ON_BAT = "power";

        # Disable CPU boost on battery (significant power savings)
        CPU_BOOST_ON_AC = 1;
        CPU_BOOST_ON_BAT = 0;

        # Platform profile (AMD laptops)
        PLATFORM_PROFILE_ON_AC = "balanced";
        PLATFORM_PROFILE_ON_BAT = "low-power";

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

        # AMD GPU - FIXED (was always "battery"/"low")
        AMDGPU_POWER_DPM_STATE_ON_AC = "balanced";
        AMDGPU_POWER_DPM_STATE_ON_BAT = "battery";
        AMDGPU_DPM_PERF_LEVEL_ON_AC = "auto";
        AMDGPU_DPM_PERF_LEVEL_ON_BAT = "low";

        # WiFi power saving
        WIFI_PWR_ON_AC = "off";
        WIFI_PWR_ON_BAT = "on";

        # Sound power saving
        SOUND_POWER_SAVE_ON_AC = 0;
        SOUND_POWER_SAVE_ON_BAT = 1;
        SOUND_POWER_SAVE_CONTROLLER = "Y";
      };
    };
  };
}
