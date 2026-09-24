{ inputs, ... }:
{
  imports = [
    # Upstream Home Manager modules the fleet's modules build on
    inputs.console-mode.homeManagerModules.default
    inputs.niri.homeModules.niri
    inputs.stylix.homeModules.stylix
    inputs.vicinae.homeManagerModules.default
    inputs.walker.homeManagerModules.default

    ./3d-printing
    ./autorandr
    ./battery-monitor
    ./chromium/user.nix
    ./communication
    ./controller
    ./controls
    ./development
    ./direnv
    ./emulation-client
    ./firefox
    ./flatpak
    ./game-streaming/user.nix
    ./games
    ./general
    ./git
    ./kanshi
    ./launcher
    ./localsend
    ./media
    ./network-monitor
    ./notifications
    ./picom
    ./polybar
    ./qutebrowser
    ./secrets
    ./shell
    ./sops/user.nix
    ./starship
    ./terminal
    ./theming
    ./file-manager/user.nix
    ./waybar
    ./window-manager
    ./x11
    ./zellij
  ];
  # useGlobalPkgs: stylix must not try to add overlays to the shared pkgs
  stylix.overlays.enable = false;
}
