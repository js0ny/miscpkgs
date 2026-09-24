#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/../.."

source_path=$(nix build --no-link --print-out-paths .#jellyfin-plugin-ldapauth-src.src)
abi=$(yq -r '.targetAbi' "$source_path/build.yaml")

if [[ ! "$abi" =~ ^[0-9]+(\.[0-9]+){3}$ ]]; then
  printf 'Invalid targetAbi in %s/build.yaml: %s\n' "$source_path" "$abi" >&2
  exit 1
fi

printf '"%s"\n' "$abi" > pkgs/jellyfin-plugin-ldapauth/target-abi.json
