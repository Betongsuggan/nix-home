{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.printing3d;
in
{
  # Named printing3d rather than 3d-printing: Nix identifiers can't start
  # with a digit, and a quoted option name would infect every usage site.
  options.printing3d = {
    enable = mkEnableOption "3D printing tooling (PrusaSlicer)";

    cad.enable = mkEnableOption "CAD modelling tools (OpenSCAD, FreeCAD)";
  };

  config = mkIf cfg.enable {
    home.packages =
      with pkgs;
      [
        unstable.prusa-slicer # stable channel lags several releases behind upstream
      ]
      ++ optionals cfg.cad.enable [
        unstable.openscad-unstable # dev snapshot; unstable channel is months fresher
        freecad-wayland # Qt-Wayland build for the Hyprland session
      ];
  };
}
