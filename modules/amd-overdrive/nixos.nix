{
  pkgs,
  config,
  lib,
  ...
}:
with lib;

{
  options.my.amd-overdrive = {
    enable = mkOption {
      description = "Enable undervolting tools";
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.my.amd-overdrive.enable {
    programs.corectrl.enable = true;

    hardware.amdgpu.overdrive = {
      enable = true;
      ppfeaturemask = "0xffffffff";
    };
  };
}
