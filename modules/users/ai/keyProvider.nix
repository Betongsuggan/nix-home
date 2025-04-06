{ pkgs, providerConfig, ... }: 
let
  keyProvider = pkgs.writeShellScriptBin providerConfig.name ''
    #!/usr/bin/env bash
    "${providerConfig.path}" "$@"
  '';
in
keyProvider
