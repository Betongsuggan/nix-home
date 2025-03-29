{ config, lib, pkgs, ... }:
with lib;

{
  options.graphics = {
    enable = mkEnableOption "Enable graphics hardware";

    nvidia = mkEnableOption "Nvidia graphics";       
  };

  config = mkIf config.graphics.enable {
    home-manager.users.${config.user}.home.packages = with pkgs; [
      vulkan-tools
    ];

    services.xserver = mkIf config.graphics.nvidia {
      videoDrivers = [ "amdgpu" ];
    };

    hardware = {
      graphics = {
        enable = true;
        enable32Bit = true;
        extraPackages = with pkgs; [
          #intel-media-driver
          mesa
          vaapiVdpau
          libvdpau-va-gl
          mangohud
        ];
        extraPackages32 = with pkgs; [
          mangohud
        ];
      };
    };

    environment.variables = {
      __NVFBC_CAPTURE = "1";
    };
  };
}
