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
        CPU_SCALING_GOVERNOR_ON_AC = config.power-management.powerModes.ac;
        CPU_SCALING_GOVERNOR_ON_BAT = config.power-management.powerModes.battery;

        #START_CHARGE_THRESH_BAT0 = 75;
        #STOP_CHARGE_THRESH_BAT0 = 90;

        #CPU_MAX_PERF_ON_AC = 50;
        #CPU_MAX_PERF_ON_BAT = 50;

        CPU_ENERGY_PERF_POLICY_ON_AC = "power";
        CPU_ENERGY_PERF_POLICY_ON_BAT = "power";

        PCIE_ASPM_ON_AC = "powersave";
        PCIE_ASPM_ON_BAT = "powersave";

        AMDGPU_POWER_DPM_ON_AC = "battery";
        AMDGPU_POWER_DPM_ON_BAT = "battery";
        AMDGPU_DPM_PERF_LEVEL_ON_AC = "low";
        AMDGPU_DPM_PERF_LEVEL_ON_BAT = "low";
      };
    };
  };
}
