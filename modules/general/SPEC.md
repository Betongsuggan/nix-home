# General

The everyday CLI toolset for every user, headless machines included: system monitoring, archives, hardware diagnostics, YubiKey management. Enabled for everyone by the base Home Manager profile.

## Usage

```nix
my.general.enable = true;
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Enable the everyday CLI toolset |

## Notes

- Enables dconf and sets `XDG_DATA_HOME`.
- Packages: btop, htop, jq, lf, lm_sensors, lshw, pciutils, usbutils, powertop, p7zip, unzip, zip, exfat, gnumake, openssl, silver-searcher, ls-lint, yubikey-manager, dconf.
- `btm` (bottom, `programs.bottom`) is the monitor with per-process GPU attribution, which btop lacks: on AMD and Intel it reads each process's DRM `fdinfo` (`gpu%` from the engine times, `gmem%` from VRAM), NVIDIA goes through NVML; the memory widget lists every GPU's VRAM and the temperature widget the GPU sensors. Sort with `C` (GPU usage) and `M` (GPU memory), search with `gpu% > 0`. No GPU-utilization graph of its own.
- GUI apps (gimp, gedit, gparted, imv, okular, vlc) come with the Home Manager `desktop` profile (`modules/profiles/home.nix`); `ryzenadj` is a system package on AMD machines (power-management with `cpuVendor = "amd"`, gaming-station).
