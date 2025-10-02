{ pkgs, config, lib, ... }: {
  imports = [
    ./audio
    ./autologin
    ./bluetooth
    ./disk-encryption
    ./docker
    ./fingerprint
    ./firefox
    ./firewall
    ./flatpak
    ./game-streaming
    ./graphics
    ./kde
    ./keyboard
    ./logitech
    ./power-management
    ./printers
    ./networking
    ./thunar
    ./touchpad
    ./undervolting
    ./wayland
    ./xserver
  ];
}
