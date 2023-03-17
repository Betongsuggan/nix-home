{ pkgs, config, lib, ... }:
{
  imports = [
    ./bluetooth
    ./disk-encryption
    ./docker
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
