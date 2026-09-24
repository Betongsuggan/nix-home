# Every Home Manager module: modules/<name>/home.nix
{ inputs, ... }:
{
  imports = [
    # Upstream Home Manager modules the fleet's modules build on
    inputs.console-mode.homeManagerModules.default
    inputs.niri.homeModules.niri
    inputs.stylix.homeModules.stylix
    inputs.vicinae.homeManagerModules.default
    inputs.walker.homeManagerModules.default

    ./printing-3d/home.nix
    ./autorandr/home.nix
    ./battery-monitor/home.nix
    ./chromium/home.nix
    ./communication/home.nix
    ./controller/home.nix
    ./controls/home.nix
    ./development/home.nix
    ./direnv/home.nix
    ./emulation-client/home.nix
    ./firefox/home.nix
    ./flatpak/home.nix
    ./game-streaming/home.nix
    ./games/home.nix
    ./general/home.nix
    ./git/home.nix
    ./kanshi/home.nix
    ./launcher/home.nix
    ./localsend/home.nix
    ./media/home.nix
    ./network-monitor/home.nix
    ./notifications/home.nix
    ./picom/home.nix
    ./polybar/home.nix
    ./qutebrowser/home.nix
    ./secrets/home.nix
    ./shell/home.nix
    ./sops/home.nix
    ./starship/home.nix
    ./terminal/home.nix
    ./theming/home.nix
    ./file-manager/home.nix
    ./waybar/home.nix
    ./window-manager/home.nix
    ./x11/home.nix
    ./zellij/home.nix
  ];
  # useGlobalPkgs: stylix must not try to add overlays to the shared pkgs
  stylix.overlays.enable = false;
}
