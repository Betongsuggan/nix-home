{ config, lib, pkgs, ... }:
with lib;

{
  options.power-management = {
    enable = mkEnableOption "Enable power management";

    mode = mkOption {
      description = "Default system power governor";
      type = types.str;
      default = "powersave";
    };
  };

  config = mkIf config.power-management.enable {
    # Prioritize performance over efficiency
    powerManagement.cpuFreqGovernor = config.power-management.mode;

    services.upower.enable = true;

    services.tlp = {
      enable = true;
      settings = {
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

        #START_CHARGE_THRESH_BAT0 = 75;
        #STOP_CHARGE_THRESH_BAT0 = 80;

        CPU_MAX_PERF_ON_AC = 100;
        CPU_MAX_PERF_ON_BAT = 40;
      };
    };
  };
}
