{ config, lib, pkgs, ... }:

{
  imports = [
    ../../modules/common
    ../../modules/system
    ./system.nix
  ];

  # Legacy user configuration (needed by modules)
  user = "birgerrydback";
  fullName = "Birger Rydback";
  extraUserGroups = [ "wheel" "networkmanager" "network" "video" "docker" ];

  system.stateVersion = "24.05";
}