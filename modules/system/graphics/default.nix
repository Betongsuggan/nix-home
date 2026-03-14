{
  config,
  lib,
  pkgs,
  ...
}:
with lib;

{
  options.graphics = {
    enable = mkEnableOption "Enable graphics hardware";

    nvidia = mkEnableOption "Nvidia graphics";

    intel = {
      enable = mkEnableOption "Intel graphics";

      generation = mkOption {
        type = types.enum [ "legacy" "modern" "arc" ];
        default = "modern";
        description = ''
          Intel GPU generation:
          - "legacy": Pre-Broadwell (Sandy Bridge, Ivy Bridge, Haswell) - uses i965 VA-API driver
          - "modern": Broadwell through Tiger Lake (2014-2020) - uses iHD VA-API driver
          - "arc": Intel Arc discrete GPUs and Meteor Lake+ (2022+) - uses iHD with extra features
        '';
      };
    };

    amd = mkOption {
      type = types.bool;
      default = true;
      description = "Enable AMD graphics support";
    };
  };

  config = mkIf config.graphics.enable {
    # Make vulkan-tools available system-wide
    environment.systemPackages = with pkgs; [ vulkan-tools ];

    # Configure video drivers based on hardware
    # Note: "modesetting" is preferred for Intel (the "intel" driver is deprecated)
    services.xserver.videoDrivers =
      (optional config.graphics.amd "amdgpu")
      ++ (optional config.graphics.nvidia "nvidia")
      ++ (optional config.graphics.intel.enable "modesetting");

    hardware = {
      graphics = {
        enable = true;
        enable32Bit = true;
        extraPackages =
          with pkgs;
          [
            libva
            libva-utils
            libva-vdpau-driver
            libvdpau-va-gl
            mangohud
          ]
          ++ (optionals config.graphics.amd [
            rocmPackages.clr.icd # OpenCL for AMD
          ])
          ++ (optionals (config.graphics.intel.enable && config.graphics.intel.generation == "legacy") [
            intel-vaapi-driver
            intel-ocl
          ])
          ++ (optionals (config.graphics.intel.enable && config.graphics.intel.generation != "legacy") [
            intel-media-driver
            intel-compute-runtime
          ]);
        extraPackages32 = with pkgs; [ mangohud ];
      };
    };

    # Intel-specific configuration
    hardware.cpu.intel.updateMicrocode = mkIf config.graphics.intel.enable true;

    # Early KMS for Intel (smoother boot, required for Plymouth)
    boot.initrd.kernelModules = mkIf config.graphics.intel.enable [ "i915" ];

    # Intel Arc: Enable GuC/HuC firmware for better performance and features
    boot.kernelParams = mkIf (config.graphics.intel.enable && config.graphics.intel.generation == "arc") [
      "i915.enable_guc=3" # Enable both GuC submission and HuC authentication
    ];

    # NVIDIA-specific configuration
    hardware.nvidia = mkIf config.graphics.nvidia {
      modesetting.enable = true;
      powerManagement.enable = true;
      open = false;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };

    # Environment variables
    environment.variables = mkMerge [
      {
        __NVFBC_CAPTURE = mkIf config.graphics.nvidia "1";
        LIBVA_DRIVER_NAME = mkIf config.graphics.intel.enable (
          if config.graphics.intel.generation == "legacy" then "i965" else "iHD"
        );
        VDPAU_DRIVER = mkIf config.graphics.intel.enable "va_gl";
      }
      (mkIf config.graphics.amd {
        RADV_PERFTEST = "gpl,ngg_culling,sam,rt"; # RDNA4 optimizations with RT
        AMD_VULKAN_ICD = "RADV";
        mesa_glthread = "true";
        VKD3D_CONFIG = "dxr11,dxr"; # DXR 1.1 for RDNA4
        ENABLE_HDR_WSI = "1"; # HDR support
      })
    ];
  };
}
