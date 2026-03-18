# Games

Provides a full Linux gaming setup including Steam, Lutris, MangoHud performance overlay, vkBasalt post-processing, Proton-GE compatibility, and various gaming utilities.

## Usage

```nix
games = {
  enable = true;
  mangohud = {
    enable = true;
    detailedMode = true;
    position = "top-left";
    fontSize = 24;
  };
  vkbasalt.enable = true;
  protonGE.enable = true;
  tools.enable = true;
};
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Enable gaming setup |
| steamBigPicture | bool | false | Auto-start Steam in Big Picture mode |
| mangohud.enable | bool | true | Enable MangoHud overlay |
| mangohud.detailedMode | bool | true | Show detailed system information in MangoHud (CPU per-core load, swap, memory, network, IO, etc.) |
| mangohud.controllerToggle | bool | false | Enable controller-based MangoHud toggle (deprecated -- use controller module instead) |
| mangohud.position | enum | "top-left" | MangoHud overlay position. One of: "top-left", "top-right", "bottom-left", "bottom-right", "top-center", "bottom-center" |
| mangohud.fontSize | int | 24 | MangoHud font size |
| vkbasalt.enable | bool | false | Enable vkBasalt post-processing |
| protonGE.enable | bool | false | Enable Proton-GE (installs to Steam compatibility tools directory) |
| tools.enable | bool | true | Install gaming tools (goverlay, protonup-qt, winetricks, protontricks, bottles, heroic) |

## Notes

- MangoHud is hidden by default and can be toggled with Shift_R+F9.
- MangoHud is enabled session-wide when active.
- Base packages always installed: chiaki, discord, libretro.snes9x, evtest, gamemode, lutris, steam, steam-run, sc-controller, vulkan-tools, mesa-demos.
