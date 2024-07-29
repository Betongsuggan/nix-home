{ config, lib, pkgs, ... }:
with lib;

{
  options.graphics = {
    enable = mkEnableOption "Enable graphics hardware";

    nvidia = mkEnableOption "Nvidia graphics";       
  };

  config = mkIf config.graphics.enable {
    hardware = {
      graphics = {
        enable = true;
        enable32Bit = true;
        extraPackages = with pkgs; [
          intel-media-driver
          mesa
          vaapiVdpau
          libvdpau-va-gl
        ];
      };
      nvidia = mkIf config.graphics.nvidia {
        modesetting.enable = true;
        package = config.boot.kernelPackages.nvidiaPackages.stable;
      };
    };

    environment.variables = {
      __NVFBC_CAPTURE = "1";
    };
  };
}
