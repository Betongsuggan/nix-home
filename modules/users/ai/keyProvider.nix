{ pkgs, config, ... }:
let
  keyProvider = pkgs.writeShellScriptBin "ai_key_provider" ''
    #!/usr/bin/env bash
    "${config.ai.keyProviderPath}" "$@"
  '';
in
keyProvider
