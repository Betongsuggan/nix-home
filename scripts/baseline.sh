#!/usr/bin/env bash
# Print "<host> <toplevel drvPath>" for every nixosConfiguration.
#
# Refactors that should not change behaviour must leave this output unchanged:
#   scripts/baseline.sh > /tmp/before   # on the old commit
#   scripts/baseline.sh > /tmp/after    # on the new commit
#   diff /tmp/before /tmp/after
#
# NIX_VAULT (default ~/nix-vault) is a local clone of nix-vault, so evaluation
# works without reaching controller over the tailnet.
set -euo pipefail

vault="${NIX_VAULT:-$HOME/nix-vault}"
flake="${1:-.}"

nix eval --no-write-lock-file --override-input nix-vault "path:$vault" --raw \
  "$flake#nixosConfigurations" \
  --apply 'hosts: builtins.concatStringsSep "" (builtins.attrValues (builtins.mapAttrs
    (name: h: "${name} ${h.config.system.build.toplevel.drvPath}\n") hosts))'
