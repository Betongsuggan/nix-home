{ config, lib, pkgs, ... }:

{
  imports = [
    ../../modules/common
    ../../modules/system
    ./system.nix
  ];

  # Legacy user configuration (needed by modules)
  user = "betongsuggan";
  fullName = "Birger Rydback";
  extraUserGroups = [ "wheel" "networkmanager" "video" "docker" ];

  system.stateVersion = "24.05";
}