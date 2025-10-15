# Emoji Visual Indicators

## Overview

`audiomenu` now uses clear emoji indicators to make it easy to identify devices at a glance!

## Visual Indicators

### Status Indicator
- **✓** - Current default device (green checkmark)
- **` `** - Not the default (space for alignment)

### Device Type Icons
- **🔊** - Audio output devices (sinks)
- **🎤** - Audio input devices (sources)

### Device-Specific Hints

The tool automatically adds contextual emojis based on device names:

- **🔈** - Built-in speakers
- **📺** - HDMI/DisplayPort outputs (monitors, TVs)
- **🎧** - USB audio devices, headsets, headphones
- **🎙️** - Microphones

## Example Display

### Output Devices (Sinks)
```
✓ 🔊 Family 17h/19h/1ah HD Audio Controller Speaker 🔈 (ID: 58)
  🔊 Radeon HDMI / DisplayPort 4 Output 📺 (ID: 73)
  🔊 Arctis 7+ Analog Stereo 🎧 (ID: 121)
```

**At a glance:**
- First device has ✓ = currently active
- 🔈 = built-in speakers
- 📺 = HDMI monitor
- 🎧 = USB headset

### Input Devices (Sources)
```
  🎤 Headphones Stereo Microphone 🎧 (ID: 59)
✓ 🎤 Digital Microphone 🎙️ (ID: 60)
  🎤 USB Audio Analog Stereo 🎧 (ID: 82)
```

**At a glance:**
- Second device has ✓ = currently active
- All have 🎤 = input devices
- 🎙️ = microphone
- 🎧 = headset mic

## Benefits

### Quick Identification
No need to read long device names - emojis tell you instantly:
- Which device is currently active (✓)
- Whether it's input or output (🔊/🎤)
- What type of device it is (🔈/📺/🎧/🎙️)

### Better UX in Launcher
When Walker/Rofi/dmenu displays the list, you can:
- Spot the current device immediately
- Identify device types by icon
- Make faster selections

### Accessibility
- Clear visual hierarchy
- Color-blind friendly (uses icons, not just colors)
- Works in any terminal/launcher that supports Unicode

## Technical Details

### Format
```
{status} {type} {device_name} {hint} (ID: {id})
```

Examples:
- `✓ 🔊 Speaker 🔈 (ID: 58)` - Active output speaker
- `  🎤 Microphone 🎙️ (ID: 60)` - Inactive input mic

### Parsing
The ID is still included at the end for reliable parsing:
```rust
AudioDevice::parse_id_from_selection(selection)
```
Extracts the ID from `(ID: 123)` regardless of emojis.

### Device Hint Detection

The tool analyzes device names for keywords:

| Keyword | Hint |
|---------|------|
| "hdmi", "displayport" | 📺 |
| "usb", "arctis" | 🎧 |
| "speaker" | 🔈 |
| "headphone" | 🎧 |
| "microphone", "mic" | 🎙️ |

### Compatibility

- ✅ Works in Walker
- ✅ Works in Rofi
- ✅ Works in dmenu (with emoji font)
- ✅ Works in Fuzzel
- ✅ Terminal-safe (Unicode emojis)

## Customization

If you want to modify the emojis, edit `src/lib.rs`:

```rust
// Change device type icons
let device_emoji = match self.device_type {
    DeviceType::Sink => "🔊",   // Output
    DeviceType::Source => "🎤", // Input
};

// Change status indicator
let status = if self.is_default {
    "✓" // Current default
} else {
    " " // Not default
};

// Modify device hints in get_device_hint()
```

## Before/After

### Before (plain text)
```
[*] Family 17h/19h/1ah HD Audio Controller Speaker (ID: 58)
    Radeon HDMI / DisplayPort 4 Output (ID: 73)
    Arctis 7+ Analog Stereo (ID: 121)
```

### After (with emojis)
```
✓ 🔊 Family 17h/19h/1ah HD Audio Controller Speaker 🔈 (ID: 58)
  🔊 Radeon HDMI / DisplayPort 4 Output 📺 (ID: 73)
  🔊 Arctis 7+ Analog Stereo 🎧 (ID: 121)
```

**Much clearer!** You can instantly see:
- ✓ marks the active device
- 🔊 shows all are outputs
- 🔈/📺/🎧 tell you what type

This makes device selection much faster and more intuitive! 🎉
