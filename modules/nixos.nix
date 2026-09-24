# Every NixOS module: modules/<name>/nixos.nix
{
  imports = import ./collect.nix "nixos.nix";
}
