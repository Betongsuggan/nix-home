# Stream Moving Feature

## The Issue

When you ran `audiomenu` and selected a new device, the **default was changed** (verified with `wpctl status`), but audio from already-playing applications (like qutebrowser) continued playing through the old device.

## Why This Happens

This is standard PipeWire behavior:
- `wpctl set-default` only changes the default for **NEW audio streams**
- Existing/active streams continue playing through their current device
- Applications don't automatically switch unless you restart them

## The Solution

Added `--move-streams` flag (enabled by default) that:
1. Sets the new default device
2. Finds all active audio streams
3. Moves them to the newly selected device

## Usage

### Default Behavior (Moves Streams)
```bash
audiomenu sink --launcher walker
```
This will:
- Change the default output device
- **Move all active streams** (qutebrowser, spotify, etc.) to the new device
- You should hear audio immediately switch!

### Only Change Default (Don't Move Streams)
```bash
audiomenu sink --launcher walker --no-move-streams
```
This will:
- Change the default output device
- Leave active streams on their current device
- Only new applications will use the new default

## How It Works

The tool now:

1. **Lists devices** - Shows all available outputs/inputs
2. **User selects** - Via Walker menu
3. **Sets default** - `wpctl set-default <ID>`
4. **Moves streams** (if enabled):
   - Queries active streams: `wpctl status` → parse Streams section
   - For each active stream: `wpctl move <stream-id> <device-id>`

## Testing

### Test With Active Audio

1. **Start some audio** (YouTube, music, etc.)
2. **Run audiomenu:**
   ```bash
   ./target/release/audiomenu sink --launcher walker
   ```
3. **Select a different device**
4. **You should hear** audio immediately switch to the new device!

### Verify Stream Movement

**Before:**
```bash
wpctl status | grep -A 20 "Streams:"
# Shows: qutebrowser → Old Device
```

**After running audiomenu:**
```bash
wpctl status | grep -A 20 "Streams:"
# Shows: qutebrowser → New Device
```

## Technical Details

### Stream ID Parsing

The tool parses wpctl status output like:
```
 └─ Streams:
       87. qutebrowser
            77. output_FL  > ALC287:playback_FL  [active]
           129. output_FR  > ALC287:playback_FR  [active]
```

It extracts stream IDs (77, 129) for sink outputs (marked with `>`).

### Moving Streams

For each stream:
```bash
wpctl move 77 58  # Move stream 77 to device 58
wpctl move 129 58 # Move stream 129 to device 58
```

Errors are silently ignored (some streams might not be movable).

## Configuration

The flag is **enabled by default** for the best user experience:

```bash
# These are equivalent:
audiomenu sink
audiomenu sink --move-streams
audiomenu sink -m

# Disable:
audiomenu sink --no-move-streams
```

## Before vs After

**Before (without stream moving):**
- ✅ Default changed in wpctl status
- ❌ Existing audio still on old device
- ⏳ Must restart applications to hear on new device

**After (with stream moving):**
- ✅ Default changed in wpctl status
- ✅ Existing audio immediately switches
- ✅ Instant feedback - you hear the change!

This makes the tool work exactly as you'd expect! 🎉
