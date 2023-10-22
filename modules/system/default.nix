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
    ./users
  ];

  config = lib.mkIf pkgs.stdenv.isLinux {

    # Pin a state version to prevent warnings
    system.stateVersion =
      config.home-manager.users.${config.user}.home.stateVersion;
  };
}
