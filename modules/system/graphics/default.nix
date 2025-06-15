{ config, lib, pkgs, ... }:
with lib;

{
  options.graphics = {
    enable = mkEnableOption "Enable graphics hardware";

    nvidia = mkEnableOption "Nvidia graphics";

    intel = mkEnableOption "Intel integrated graphics";

    amd = mkOption {
      type = types.bool;
      default = true;
      description = "Enable AMD graphics support";
    };
  };

  config = mkIf config.graphics.enable {
    home-manager.users.${config.user}.home.packages = with pkgs; [
      vulkan-tools
    ];

    # Configure video drivers based on hardware
    services.xserver.videoDrivers =
      (optional config.graphics.amd "amdgpu") ++
      (optional config.graphics.nvidia "nvidia") ++
      (optional config.graphics.intel "intel");

    hardware = {
      graphics = {
        enable = true;
        enable32Bit = true;
        extraPackages = with pkgs; [
          mesa
          vaapiVdpau
          libvdpau-va-gl
          mangohud
        ] ++ (optionals config.graphics.intel [
          vaapiIntel
          intel-media-driver
          #intel-media-driver # LIBVA_DRIVER_NAME=iHD
          #intel-compute-runtime # OpenCL support
          #intel-vaapi-driver # LIBVA_DRIVER_NAME=i965 (older but can be more stable)
        ]);
        extraPackages32 = with pkgs; [
          mangohud
        ];
      };
    };

    # Intel-specific configuration
    hardware.cpu.intel.updateMicrocode = mkIf config.graphics.intel true;

    # NVIDIA-specific configuration
    hardware.nvidia = mkIf config.graphics.nvidia {
      modesetting.enable = true;
      powerManagement.enable = true;
      open = false;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };

    # Environment variables
    environment.variables = {
      __NVFBC_CAPTURE = mkIf config.graphics.nvidia "1";
      # Intel-specific environment variables
      #LIBVA_DRIVER_NAME = mkIf config.graphics.intel "iHD";
    };
  };
}
