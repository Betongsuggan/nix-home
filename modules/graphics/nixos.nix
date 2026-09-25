{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib;

{
  options.my.graphics = {
    enable = mkEnableOption "Enable graphics hardware";

    nvidia = mkEnableOption "Nvidia graphics";

    intel = {
      enable = mkEnableOption "Intel graphics";

      generation = mkOption {
        type = types.enum [
          "legacy"
          "modern"
          "arc"
        ];
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
      default = false;
      description = "Enable AMD graphics support";
    };

    gaming = mkOption {
      type = types.bool;
      default = inputs.self.lib.anyHomeUser config (u: u.my.games.enable);
      defaultText = literalExpression "any Home Manager user has my.games.enable";
      description = "32-bit graphics drivers (Steam, Wine), the MangoHud Vulkan layer and vulkan-tools.";
    };

    compute = mkOption {
      type = types.bool;
      default = false;
      description = "OpenCL runtimes (ROCm for AMD, compute-runtime for Intel), for GPU compute workloads.";
    };
  };

  config = mkIf config.my.graphics.enable {
    environment.systemPackages = optional config.my.graphics.gaming pkgs.vulkan-tools;

    # Configure video drivers based on hardware
    # Note: "modesetting" is preferred for Intel (the "intel" driver is deprecated)
    services.xserver.videoDrivers =
      (optional config.my.graphics.amd "amdgpu")
      ++ (optional config.my.graphics.nvidia "nvidia")
      ++ (optional config.my.graphics.intel.enable "modesetting");

    hardware = {
      graphics = {
        enable = true;
        enable32Bit = config.my.graphics.gaming;
        extraPackages =
          with pkgs;
          [
            libva
            libva-utils
            libva-vdpau-driver
            libvdpau-va-gl
          ]
          ++ optional config.my.graphics.gaming mangohud
          ++ (optionals (config.my.graphics.amd && config.my.graphics.compute) [
            rocmPackages.clr.icd # OpenCL for AMD
          ])
          ++ (
            optionals (config.my.graphics.intel.enable && config.my.graphics.intel.generation == "legacy") [
              intel-vaapi-driver
            ]
            ++ optional config.my.graphics.compute intel-ocl
          )
          ++ (
            optionals (config.my.graphics.intel.enable && config.my.graphics.intel.generation != "legacy") [
              intel-media-driver
            ]
            ++ optional config.my.graphics.compute intel-compute-runtime
          )
          ++ (optionals config.my.graphics.nvidia [
            nvidia-vaapi-driver
          ]);
        extraPackages32 = optional config.my.graphics.gaming pkgs.mangohud;
      };
    };

    # Intel-specific configuration
    hardware.cpu.intel.updateMicrocode = mkIf config.my.graphics.intel.enable true;

    # Early KMS for Intel (smoother boot, required for Plymouth)
    boot.initrd.kernelModules = mkIf config.my.graphics.intel.enable [ "i915" ];

    # Intel Arc: Enable GuC/HuC firmware for better performance and features
    boot.kernelParams =
      mkIf (config.my.graphics.intel.enable && config.my.graphics.intel.generation == "arc")
        [
          "i915.enable_guc=3" # Enable both GuC submission and HuC authentication
        ];

    # NVIDIA-specific configuration
    hardware.nvidia = mkIf config.my.graphics.nvidia {
      modesetting.enable = true;
      powerManagement.enable = false;
      open = false;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };

    # Environment variables
    environment.variables = mkMerge [
      {
        __NVFBC_CAPTURE = mkIf config.my.graphics.nvidia "1";
        LIBVA_DRIVER_NAME =
          if config.my.graphics.nvidia then
            "nvidia"
          else
            mkIf (config.my.graphics.intel.enable || config.my.graphics.amd) (
              if config.my.graphics.intel.enable then
                (if config.my.graphics.intel.generation == "legacy" then "i965" else "iHD")
              else
                "radeonsi"
            );
        VDPAU_DRIVER = mkIf config.my.graphics.intel.enable "va_gl";
      }
      (mkIf config.my.graphics.nvidia {
        __GLX_VENDOR_LIBRARY_NAME = "nvidia";
        GBM_BACKEND = "nvidia-drm";
        NVD_BACKEND = "direct";
        __GL_GSYNC_ALLOWED = "1";
        __GL_VRR_ALLOWED = "1";
        ELECTRON_OZONE_PLATFORM_HINT = "auto";
        VK_DRIVER_FILES = "/run/opengl-driver/share/vulkan/icd.d/nvidia_icd.x86_64.json";
      })
      (mkIf config.my.graphics.amd {
        # No RADV/vkd3d tuning vars: modern Mesa enables gpl/ngg/sam/rt by
        # default, and forcing VKD3D_CONFIG=dxr makes games silently enable
        # ray tracing paths that tank performance under vkd3d-proton.
        ENABLE_HDR_WSI = "1"; # HDR support
      })
    ];
  };
}
