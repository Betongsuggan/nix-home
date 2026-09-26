# Audio

Configures PipeWire-based audio with ALSA, PulseAudio compatibility, and WirePlumber. Includes enhanced Bluetooth audio codec support and an optional low-latency mode for gaming.

## Usage

```nix
my.audio = {
  enable = true;
  lowLatency = true;
};
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Enable sound hardware via PipeWire |
| lowLatency | bool | false | Low-latency mode for gaming (48 kHz, min quantum 64) via nix-gaming's `services.pipewire.lowLatency` |

## Notes

- Enables `rtkit` for real-time scheduling priority.
- Installs `pavucontrol` (volume control GUI) and `libfreeaptx` (aptX codec library).
- WirePlumber is configured with enhanced Bluetooth codecs: SBC, SBC-XQ, AAC, LDAC, aptX, aptX HD, aptX LL, aptX LL Duplex, and aptX Adaptive.
- Low-latency mode delegates to nix-gaming's `pipewireLowLatency` NixOS module (imported by this module): `default.clock.min-quantum = 64` at 48 kHz, `libpipewire-module-rt` (nice -15, rt.prio 88), PulseAudio clients forced to 64/48000 (`pulse.min.req/quantum/frag`) and client `node.latency`. The ALSA-level overrides (`services.pipewire.lowLatency.alsa.*`) stay off: forcing S32LE/rate breaks HDMI sinks. This replaced a hand-written `99-low-latency` block; only the quantum floor is enforced now, the default quantum is PipeWire's.
