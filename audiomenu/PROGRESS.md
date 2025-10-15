# audiomenu - Development Progress

## Phase 1: Project Setup ✅

### Completed Tasks
- [x] Create project directory structure
- [x] Initialize Rust project with Cargo.toml
- [x] Create flake.nix with Rust build configuration
- [x] Set up basic project structure (lib.rs, main.rs, modules)
- [x] Create CLI argument parser with clap
- [x] Add basic audio backend trait and PipeWire stub
- [x] Test building the project with Nix flake

### Project Structure
```
audiomenu/
├── src/
│   ├── main.rs              ✅ Entry point with error handling
│   ├── lib.rs               ✅ Core types (DeviceType, AudioDevice)
│   ├── backend/
│   │   ├── mod.rs           ✅ AudioBackend trait & Backend enum
│   │   └── pipewire.rs      🚧 PipeWire impl (stub, needs parsing)
│   ├── cli/
│   │   └── mod.rs           ✅ CLI args with clap
│   └── launcher/
│       └── mod.rs           ✅ Launcher integration (Walker, Rofi, etc.)
├── Cargo.toml               ✅
├── flake.nix                ✅ Nix flake with dev shell
├── .gitignore               ✅
├── README.md                ✅
└── PROGRESS.md              ✅ This file
```

### Features Implemented
- ✅ CLI argument parsing (device type, launcher, backend)
- ✅ Multi-backend support (trait-based design)
- ✅ Multi-launcher support (Walker, Rofi, dmenu, Fuzzel)
- ✅ Nix flake for reproducible builds
- ✅ Error handling with anyhow
- 🚧 PipeWire backend (stub created, needs device parsing)

### Current State
The project **compiles successfully** with both Cargo and Nix!

The boilerplate is complete and we have:
- A working CLI parser
- Backend trait system ready for PipeWire/PulseAudio
- Launcher abstraction for dmenu-style integration
- Clean project structure

## Phase 2: Core Implementation 🚧

### Next Tasks
1. [ ] Implement PipeWire device listing (parse wpctl status output)
2. [ ] Test launcher integration with Walker
3. [ ] Test device selection and set-default
4. [ ] Add proper error handling and user feedback
5. [ ] End-to-end testing

### Implementation Notes

#### wpctl status output format
```
Audio
 ├─ Sinks:
 │  *   58. Family 17h/19h/1ah HD Audio Controller Speaker [vol: 0.54]
 │      73. Radeon High Definition Audio Controller [...] [vol: 0.40]
 ├─ Sources:
 │      59. Family 17h/19h/1ah HD Audio Controller Headphones [...] [vol: 1.00]
 │  *   82. USB Audio Analog Stereo [vol: 0.69]
```

Need to parse:
- Device ID (e.g., 58, 73)
- Device name/description
- Default marker (*)
- Section (Sinks vs Sources)

#### Backend trait
```rust
pub trait AudioBackend {
    fn list_devices(&self, device_type: DeviceType) -> Result<Vec<AudioDevice>>;
    fn set_default(&self, device_id: u32) -> Result<()>;
    fn name(&self) -> &str;
}
```

#### Device type
```rust
pub enum DeviceType {
    Sink,   // Output (speakers, headphones)
    Source, // Input (microphones)
}
```

## Phase 3: Integration & Testing 📋

### Testing Checklist
- [ ] Test with Walker launcher
- [ ] Test sink (output) selection
- [ ] Test source (input) selection
- [ ] Test with multiple devices
- [ ] Test default device switching
- [ ] Verify wpctl integration
- [ ] Error handling (no devices, launcher cancelled, etc.)

### Integration with nix-home
Once stable, add to `modules/users/launcher/default.nix`:
```nix
launcherAudioCmd = { mode ? "sink", additionalArgs ? [] }:
  if cfg.backend == "walker" then
    "${pkgs.audiomenu}/bin/audiomenu ${mode} --launcher walker"
  else
    throw "Unsupported launcher backend: ${cfg.backend}";
```

## Building & Testing

### Build with Cargo
```bash
cd audiomenu
cargo build
cargo run -- sink --launcher walker
```

### Build with Nix
```bash
cd audiomenu
nix build
./result/bin/audiomenu --help
```

### Development Shell
```bash
cd audiomenu
nix develop
```

## Future Enhancements
- [ ] PulseAudio backend support
- [ ] Icon support (like iwmenu/bzmenu)
- [ ] Custom launcher command support
- [ ] Configuration file support
- [ ] Hotkey integration examples
- [ ] Package for nixpkgs
