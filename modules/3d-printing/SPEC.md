# 3D Printing

3D printing toolchain: the PrusaSlicer slicer, and optionally CAD modelling tools
(OpenSCAD dev snapshot, FreeCAD).

The option namespace is `printing3d` (not `3d-printing`): Nix identifiers can't start
with a digit, and quoting the attribute at every usage site isn't worth it.

## Usage

```nix
printing3d = {
  enable = true;
  cad.enable = true; # optional: OpenSCAD + FreeCAD
};
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| enable | bool | false | Install PrusaSlicer (from nixpkgs unstable) |
| cad.enable | bool | false | Also install OpenSCAD (dev snapshot, from unstable) and FreeCAD (Wayland build) |

## Notes

- PrusaSlicer comes from `pkgs.unstable` (2.9.6 at the current pin) since the stable
  channel lags upstream releases. The PrusaSlicer 3.0 preview (2026-09) is
  Linux-distributed only as a Flatpak on flathub-beta and is deliberately not used
  here; 3.0 will arrive through this module once it's released as stable and packaged
  in nixpkgs (after a `nix flake update` of the `nixpkgs-unstable` input).
- OpenSCAD uses the `openscad-unstable` dev-snapshot attribute (much newer features
  than the 2021 stable release), taken from the unstable channel where the snapshot
  is months fresher.
- FreeCAD uses the `freecad-wayland` variant so it runs natively under the Hyprland
  Wayland session; same version as `freecad` (1.1.3 on the current stable pin).
