{ pkgs, config, lib, ... }:
{
  imports = [
    ./bluetooth
    ./disk-encryption
    ./docker
    ./fingerprint
    ./firewall
    ./graphics
    ./kde
    ./power-management
    ./printers
    ./sound
    ./touchpad
    ./wayland
    ./xserver
  ];
}
