#!/usr/bin/env bash
# Reminds Claude to update SPEC.md when module or host files are modified.
set -euo pipefail

input=$(cat)
file=$(echo "$input" | jq -r '.tool_input.file_path // empty')

if [[ -z "$file" ]]; then
  exit 0
fi

# Don't remind when editing the SPEC.md itself
if [[ "$file" == *"/SPEC.md" ]]; then
  exit 0
fi

# --- modules/<name>/ ---
if [[ "$file" == *"/modules/"* ]]; then
  # Extract module name: the first path component after modules/
  module=$(echo "$file" | sed -n 's|.*/modules/\([^/]*\)/.*|\1|p')
  if [[ -z "$module" ]]; then
    exit 0
  fi
  # Skip aggregator files (system.nix, user.nix) and common
  if [[ "$module" == "system.nix" || "$module" == "user.nix" || "$module" == "common" ]]; then
    exit 0
  fi
  repo_root=$(echo "$file" | sed 's|\(.*\)/modules/.*|\1|')
  spec_file="${repo_root}/modules/${module}/SPEC.md"
  if [[ -f "$spec_file" ]]; then
    echo "IMPORTANT: You modified a file in modules/${module}/. You MUST check modules/${module}/SPEC.md for drift. If your changes affect module options or behavior, update the spec BEFORE continuing with other work."
    exit 2
  fi
  exit 0
fi

# --- hosts/<name>/ ---
if [[ "$file" == *"/hosts/"* ]]; then
  host=$(echo "$file" | sed -n 's|.*/hosts/\([^/]*\)/.*|\1|p')
  if [[ -z "$host" ]]; then
    exit 0
  fi
  repo_root=$(echo "$file" | sed 's|\(.*\)/hosts/.*|\1|')
  spec_file="${repo_root}/hosts/${host}/SPEC.md"
  if [[ -f "$spec_file" ]]; then
    echo "IMPORTANT: You modified a file in hosts/${host}/. You MUST check hosts/${host}/SPEC.md for drift. If your changes affect host configuration or services, update the spec BEFORE continuing with other work."
    exit 2
  fi
  exit 0
fi
