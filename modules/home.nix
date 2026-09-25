# Every Home Manager module: modules/<name>/home.nix
{ inputs, ... }:
{
  imports = [
    # Upstream Home Manager modules the fleet's modules build on
    inputs.console-mode.homeManagerModules.default
    inputs.niri.homeModules.niri
    inputs.stylix.homeModules.stylix
    inputs.walker.homeManagerModules.default
  ]
  ++ import ./collect.nix "home.nix";
  # useGlobalPkgs: stylix must not try to add overlays to the shared pkgs
  stylix.overlays.enable = false;
}
