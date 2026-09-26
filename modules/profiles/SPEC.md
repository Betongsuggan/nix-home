# Profiles

Roles a host (or user) can take. Each profile only sets defaults (`mkDefault`), so a host can still switch any single module on or off. The always-on baseline for every host lives in `modules/common`.

## Usage

```nix
# hosts/<host>/system.nix
my.profiles.laptop.enable = true;          # bits, private-laptop
my.profiles.gaming-station.enable = true;  # desktop, island-stationary
```

## NixOS profiles (`nixos.nix`)

| Profile | Implies | Sets |
|---------|---------|------|
| `workstation` | | all firmware, fwupd, `my.{audio,bluetooth,graphics,network-manager,printers,wayland-security}`, and the Home Manager `desktop` profile for every user on the host |
| `laptop` | workstation | `my.power-management`, libinput touchpad (tap, flat accel, disable-while-typing), video-group backlight access, `my.battery-monitor` for every user, at most 2 parallel Nix builds, zstd zram swap (25% of RAM) ahead of any disk swap, and nothing resident that is only occasionally needed: sshd per connection, fwupd only when run (no refresh timer), no cups-browsed, no gvfs GOA/afc/gphoto2 monitors |
| `gaming-station` | workstation | `gamer` account (unprivileged; groups for input, audio and gamemode) with getty autologin on tty1, secure boot, zen kernel, gaming kernel params and sysctls (`vm.max_map_count` comes from the games module's nix-gaming `platformOptimizations`), zram, performance governor, gamemode (+ mangohud), low-latency audio, DualSense Bluetooth wake, restic target for controller's backups |

Hardware specifics (GPU vendor, CPU vendor, disks, kernel modules) stay in the host.

## Home Manager (`home.nix`)

- Every user: `my.{general,git,shell,starship,terminal,theming}` enabled; the git identity comes from `lib.accounts`.
- `my.profiles.desktop` (turned on by the NixOS `workstation` profile): `my.{chromium,communication,file-manager,launcher,window-manager}` enabled, plus the desktop apps gimp, gedit, gparted, imv, okular and vlc (wine comes with `my.games`), and the standard XDG folders (`xdg.userDirs`: Desktop, Documents, Downloads, Music, Pictures, Videos, Templates, Public), written to `user-dirs.dirs` and created, so browsers, Slack and file dialogs all save to the same `~/Downloads` etc.

## Notes

- Profiles that touch Home Manager only do so when the host has Home Manager users, so they also evaluate on hosts like mail or island-pi.
