# Power Management

Configures system power management using TLP, with vendor-specific tuning for AMD/Intel CPUs and AMD/Intel/NVIDIA GPUs. Manages CPU frequency scaling, lid close behavior, PCIe/USB/SATA power saving, and WiFi/audio power policies across AC and battery power states.

## Usage

```nix
power-management = {
  enable = true;
  cpuVendor = "amd";
  gpuVendor = "amd";
  powerModes = {
    ac = "performance";
    battery = "powersave";
  };
};
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Enable power management |
| cpuVendor | null or "amd" or "intel" | null | CPU vendor for vendor-specific power settings (P-State, energy policy, platform profile) |
| gpuVendor | null or "amd" or "intel" or "nvidia" | null | GPU vendor for vendor-specific power settings |
| powerModes.ac | str | "performance" | Default CPU scaling governor on AC power |
| powerModes.battery | str | "powersave" | Default CPU scaling governor on battery power |

## Notes

- Enables TLP for automatic power state switching between AC and battery.
- Enables upower for power device monitoring.
- Lid close behavior is gated on external displays, not power source: with an external monitor connected (logind "docked" state: docking station or more than one connected display) the lid is ignored; otherwise lid close suspends, on AC and battery alike. Inactivity suspend (hypridle) is unaffected. Hyprland handles locking and panel disable via lid switch binds.
- AMD CPU: configures P-State energy policy and platform profile.
- Intel CPU: configures HWP energy policy.
- AMD GPU: configures DPM state and performance level per power source.
