# Audio

Configures PipeWire-based audio with ALSA, PulseAudio compatibility, and WirePlumber. Includes enhanced Bluetooth audio codec support and an optional low-latency mode for gaming.

## Usage

```nix
audio = {
  enable = true;
  lowLatency = true;
};
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Enable sound hardware via PipeWire |
| lowLatency | bool | false | Low-latency mode for gaming (48kHz, quantum 64) |

## Notes

- Enables `rtkit` for real-time scheduling priority.
- Installs `pavucontrol` (volume control GUI) and `libfreeaptx` (aptX codec library).
- WirePlumber is configured with enhanced Bluetooth codecs: SBC, SBC-XQ, AAC, LDAC, aptX, aptX HD, aptX LL, aptX LL Duplex, and aptX Adaptive.
- Low-latency mode sets the PipeWire clock to 48kHz with quantum range 32--256, centered at 64.
