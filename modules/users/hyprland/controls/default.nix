{ pkgs, ... }:
{
  utils = import ./utilNotifications.nix { inherit pkgs; };
  mediaPlayer = import ./mediaPlayerControls.nix { inherit pkgs; };
  volume = import ./volumeControls.nix { inherit pkgs; };
  brightness = import ./brightnessControls.nix { inherit pkgs; };
  power = import ./powerControls.nix { inherit pkgs; };
}
