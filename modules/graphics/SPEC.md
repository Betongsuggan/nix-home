# Graphics

Configures GPU drivers and hardware acceleration for AMD, NVIDIA, and Intel graphics. Sets up VA-API, VDPAU, Vulkan, and OpenCL support with generation-appropriate driver packages and performance tuning.

## Usage

```nix
graphics = {
  enable = true;
  amd = true;
  nvidia = false;
  intel.enable = false;
};
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Enable graphics hardware support |
| amd | bool | false | Enable AMD graphics support |
| nvidia | bool | false | Enable NVIDIA graphics support |
| intel.enable | bool | false | Enable Intel graphics support |
| intel.generation | enum: "legacy" "modern" "arc" | "modern" | Intel GPU generation (see below) |

Intel GPU generations:
- `legacy` -- Pre-Broadwell (Sandy Bridge, Ivy Bridge, Haswell). Uses i965 VA-API driver.
- `modern` -- Broadwell through Tiger Lake (2014-2020). Uses iHD VA-API driver.
- `arc` -- Intel Arc discrete GPUs and Meteor Lake+ (2022+). Uses iHD with GuC/HuC firmware enabled.

## Notes

- 32-bit graphics libraries and MangoHud are included for game compatibility.
- AMD configuration relies on Mesa/RADV defaults and only sets the HDR environment variable (`ENABLE_HDR_WSI`) plus the VA-API driver name. Deliberately **no** `RADV_PERFTEST`, `VKD3D_CONFIG=dxr*`, `AMD_VULKAN_ICD`, or `mesa_glthread`: on modern Mesa those features are already default, setting `RADV_PERFTEST` puts the driver in a non-conformant testing mode, and force-enabling DXR makes games silently turn on ray-tracing paths that can collapse performance under vkd3d-proton (diagnosed July 2026: UE5 title CPU-bound at 20 fps with the GPU 25% busy, `vkd3d_queue` thread pegged in kernel time).
- NVIDIA uses the stable proprietary driver with modesetting enabled and power management disabled (desktop default; laptop hosts should override `powerManagement.enable = true`). Sets `GBM_BACKEND`, `__GLX_VENDOR_LIBRARY_NAME`, `LIBVA_DRIVER_NAME`, `NVD_BACKEND`, and VRR env vars for Wayland compositor compatibility. Includes `nvidia-vaapi-driver` for hardware video decode. Sets `VK_DRIVER_FILES` to the NVIDIA ICD only, excluding Mesa software renderers (lavapipe) and other unused ICDs. Hosts using `programs.steam` should enable it at the system level for proper GPU driver injection inside Steam's sandbox.
- Intel `arc` generation enables GuC submission and HuC authentication via kernel parameters.
- `vulkan-tools` is installed system-wide for diagnostics.
