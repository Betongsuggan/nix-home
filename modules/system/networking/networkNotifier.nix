{ pkgs, ... }:
let
  networkNotifier = pkgs.writeShellScriptBin "network-notifier" ''
    #!/usr/bin/env bash
    
    ${pkgs.dunst}/bin/dunstify "hello"
  '';
in
networkNotifier
