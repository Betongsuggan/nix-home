{ pkgs, config, lib, ... }:
with lib;

{
  options.undervolting = {
    enable = mkOption {
      description = "Enable undervolting tools";
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.undervolting.enable {
    programs.corectrl.enable = true;
    
    hardware.amdgpu.overdrive = {
      enable = true;
      ppfeaturemask = "0xffffffff";
    };
  };
}
