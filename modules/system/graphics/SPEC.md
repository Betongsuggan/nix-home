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
| amd | bool | true | Enable AMD graphics support |
| nvidia | bool | false | Enable NVIDIA graphics support |
| intel.enable | bool | false | Enable Intel graphics support |
| intel.generation | enum: "legacy" "modern" "arc" | "modern" | Intel GPU generation (see below) |

Intel GPU generations:
- `legacy` -- Pre-Broadwell (Sandy Bridge, Ivy Bridge, Haswell). Uses i965 VA-API driver.
- `modern` -- Broadwell through Tiger Lake (2014-2020). Uses iHD VA-API driver.
- `arc` -- Intel Arc discrete GPUs and Meteor Lake+ (2022+). Uses iHD with GuC/HuC firmware enabled.

## Notes

- 32-bit graphics libraries and MangoHud are included for game compatibility.
- AMD configuration sets RADV as the Vulkan ICD, enables mesa_glthread, and configures DXR 1.1 and HDR environment variables.
- NVIDIA uses the stable proprietary driver with modesetting and power management enabled.
- Intel `arc` generation enables GuC submission and HuC authentication via kernel parameters.
- `vulkan-tools` is installed system-wide for diagnostics.
