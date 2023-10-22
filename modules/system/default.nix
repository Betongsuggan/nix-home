{ pkgs, config, lib, ... }:
{
  imports = [
    ./bluetooth
    ./disk-encryption
    ./docker
    ./fingerprint
    ./firefox
    ./firewall
    ./graphics
    ./kde
    ./power-management
    ./printers
    ./audio
    ./touchpad
    ./wayland
    ./xserver
  ];
}
