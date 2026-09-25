# Power Management

Configures system power management using TLP, with vendor-specific tuning for AMD/Intel CPUs and AMD/Intel/NVIDIA GPUs. Manages CPU frequency scaling, lid close behavior, PCIe/USB/SATA power saving, and WiFi/audio power policies across AC and battery power states.

## Usage

```nix
my.power-management = {
  enable = true;
  cpuVendor = "amd";
  gpuVendor = "amd";
  powerModes = {
    ac = "performance";
    battery = "powersave";
  };
};
```

Capping peak draw on AC and recording power telemetry (see *Power-loss forensics*):

```nix
my.power-management = {
  enable = true;
  cpuVendor = "amd";
  gpuVendor = "amd";
  platformProfiles.ac = "low-power";
  amdgpuPerfLevel.ac = "low";
  forensics.enable = true;
};
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Enable power management |
| cpuVendor | null or "amd" or "intel" | null | CPU vendor for vendor-specific power settings (P-State, energy policy, platform profile) |
| gpuVendor | null or "amd" or "intel" or "nvidia" | null | GPU vendor for vendor-specific power settings |
| powerModes.ac | str | "powersave" | CPU scaling governor on AC; with amd_pstate/intel_pstate, `powersave` lets the energy-performance preference (balance_performance on AC) steer, while `performance` would pin it |
| powerModes.battery | str | "powersave" | Default CPU scaling governor on battery power |
| platformProfiles.ac | str | "balanced" | ACPI platform profile on AC (AMD CPU only) |
| platformProfiles.battery | str | "low-power" | ACPI platform profile on battery (AMD CPU only) |
| amdgpuPerfLevel.ac | str | "auto" | amdgpu DPM performance level on AC (AMD GPU only) |
| amdgpuPerfLevel.battery | str | "auto" | amdgpu DPM performance level on battery (AMD GPU only; `low` pins the lowest clocks) |
| amdgpuAbmLevel.ac / .battery | int 0-4 | 0 / 3 | amdgpu Adaptive Backlight Management (lower backlight, contrast compensated); the panel is usually the largest consumer on battery |
| forensics.enable | bool | false | Record power telemetry and make oopses panic (see below) |
| forensics.interval | int | 5 | Seconds between telemetry samples |

## Notes

- Enables TLP for automatic power state switching between AC and battery.
- Enables upower for power device monitoring.
- Lid close behavior is gated on external displays, not power source: with an external monitor connected (logind "docked" state: docking station or more than one connected display) the lid is ignored; otherwise lid close suspends, on AC and battery alike. Inactivity suspend (hypridle) is unaffected. Hyprland handles locking and panel disable via lid switch binds.
- AMD CPU: configures P-State energy policy and platform profile.
- Intel CPU: configures HWP energy policy.
- AMD GPU: configures DPM state and performance level per power source.

## Power-loss forensics

`forensics.enable` targets one specific failure: a machine that dies instantly with
**nothing** in the journal. A hard power cut leaves no trace precisely because every
normal logging path is buffered, so the seconds that would identify the cause are the
seconds that get lost.

It sets up two things:

- **`power-telemetry.service`** samples `BAT0`/`AC` sysfs every `forensics.interval`
  seconds into `/var/log/power-telemetry.log`, calling `sync --data` after each line so
  the final sample survives a cut. Records `present`, `status`, AC `online`,
  `voltage_now`, `power_now`, `energy_now`, `capacity` and the k10temp reading.
  Rotated daily, 14 days retained.
- **`kernel.panic_on_oops=1` / `kernel.panic=10`** so a kernel oops becomes a panic that
  lands in pstore and reboots, rather than limping on and dying unrecorded.

Reading the result after a crash: compare the tail of the log against the crash time
from `journalctl --list-boots`.

| Last sample shows | Reading |
|---|---|
| `present=0`, or `volt_uV` sagging | Battery pack dropping off the bus |
| `power_uW` spiking just before | Transient draw exceeding what the charger alone supplies |
| `tctl_mC` climbing past ~95000 | Thermal event |
| Everything nominal right up to the cut | Points away from the battery, toward firmware/EC or the board |

Note that `panic_on_oops` converts otherwise-survivable oopses into reboots. That is the
right trade while diagnosing, but it is a diagnostic posture rather than a default; it
and any lowered `platformProfiles`/`amdgpuPerfLevel` caps are meant to be reverted once
the cause is found.
- amdgpu settings use TLP's real keys (`RADEON_DPM_PERF_LEVEL_ON_*`, `AMDGPU_ABM_LEVEL_ON_*`); earlier `AMDGPU_*DPM*` names did not exist in TLP and were ignored.
- With `cpuVendor = "intel"`, thermald is enabled as well.
