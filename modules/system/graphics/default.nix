{ config, lib, pkgs, ... }:
with lib;

{
  options.graphics = {
    enable = mkEnableOption "Enable graphics hardware";

    nvidia = mkEnableOption "Nvidia graphics";       
  };

  config = mkIf config.graphics.enable {
    services.xserver = mkIf config.graphics.nvidia {
      videoDrivers = [ "nvidia" ];
    };
    hardware = {
      nvidia = mkIf config.graphics.nvidia {
        modesetting.enable = true;
        #open = true;
        package = config.boot.kernelPackages.nvidiaPackages.stable;
      };
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
    };

    environment.variables = {
      __NVFBC_CAPTURE = "1";
    };
  };
}
