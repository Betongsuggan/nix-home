{ pkgs, ... }:
let
  networkNotifier = pkgs.writeShellScriptBin "network-notifier.sh" ''
    #!/usr/bin/env bash
    
    echo "hello"
  '';
in
{
  inherit networkNotifier;
}
