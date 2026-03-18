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

# --- modules/system/<name>/ ---
if [[ "$file" == *"/modules/system/"* ]]; then
  module=$(echo "$file" | sed -n 's|.*/modules/system/\([^/]*\)/.*|\1|p')
  if [[ -z "$module" ]]; then
    exit 0
  fi
  repo_root=$(echo "$file" | sed 's|\(.*\)/modules/.*|\1|')
  spec_file="${repo_root}/modules/system/${module}/SPEC.md"
  if [[ -f "$spec_file" ]]; then
    echo "IMPORTANT: You modified a file in modules/system/${module}/. You MUST check modules/system/${module}/SPEC.md for drift. If your changes affect module options or behavior, update the spec BEFORE continuing with other work."
    exit 2
  fi
  exit 0
fi

# --- modules/users/<name>/ ---
if [[ "$file" == *"/modules/users/"* ]]; then
  module=$(echo "$file" | sed -n 's|.*/modules/users/\([^/]*\)/.*|\1|p')
  if [[ -z "$module" ]]; then
    exit 0
  fi
  repo_root=$(echo "$file" | sed 's|\(.*\)/modules/.*|\1|')
  spec_file="${repo_root}/modules/users/${module}/SPEC.md"
  if [[ -f "$spec_file" ]]; then
    echo "IMPORTANT: You modified a file in modules/users/${module}/. You MUST check modules/users/${module}/SPEC.md for drift. If your changes affect module options or behavior, update the spec BEFORE continuing with other work."
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
