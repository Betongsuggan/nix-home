# Interactive Test Instructions

The fix has been applied! Walker's dmenu mode now uses the correct `-d` flag.

## Quick Test

Run this command and Walker should pop up with your audio devices:

```bash
cd /home/birgerrydback/nix-home/audiomenu
./target/release/audiomenu sink --launcher walker
```

### What Should Happen:

1. ✅ Walker window opens immediately
2. ✅ You see a list of your 5 output devices:
   - `[*] Family 17h/19h/1ah HD Audio Controller Speaker (ID: 58)` ← Current default
   - `    Radeon HDMI / DisplayPort 4 Output (ID: 73)`
   - `    Radeon HDMI / DisplayPort 1 Output (ID: 112)`
   - `    Radeon HDMI / DisplayPort 2 Output (ID: 120)`
   - `    Radeon HDMI / DisplayPort 3 Output (ID: 128)`
3. ✅ Select a device with arrow keys and press Enter
4. ✅ You see: `Successfully set default sink to device ID: XX`
5. ✅ Verify with: `wpctl status | grep -A 5 "Sinks:"`

## Test Input Devices

```bash
./target/release/audiomenu source --launcher walker
```

Should show your 3 input devices:
- `    Family 17h/19h/1ah HD Audio Controller Headphones Stereo Microphone (ID: 59)`
- `    Family 17h/19h/1ah HD Audio Controller Digital Microphone (ID: 60)`
- `[*] USB Audio Analog Stereo (ID: 82)` ← Current default

## What Was Fixed

**Problem**: Walker wasn't showing any devices

**Root Cause**:
- Used `--dmenu --exit` flags
- Should use shorthand `-d` flag instead
- When Walker runs as a service, it needs the short flag

**Solution**: Changed Walker command from:
```
walker --dmenu --exit --placeholder "prompt"
```
to:
```
walker -d -p "prompt"
```

## If It Works

You should now be able to:
- Switch audio output devices quickly
- Switch audio input devices
- See which device is currently default (marked with `[*]`)

Try it out and let me know if you see the devices in Walker now! 🎉
