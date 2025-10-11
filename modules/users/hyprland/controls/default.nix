{ config, pkgs, ... }:
{
  utils = import ./utilNotifications.nix { inherit config pkgs; };
  mediaPlayer = import ./mediaPlayerControls.nix { inherit config pkgs; };
  volume = import ./volumeControls.nix { inherit config pkgs; };
  brightness = import ./brightnessControls.nix { inherit config pkgs; };
  power = import ./powerControls.nix { inherit config pkgs; };
}
