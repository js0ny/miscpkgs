#!/usr/bin/env bash
# Updates edstem-cli, and re-pins the esbuild build tool when upstream's lockfile moves it.
set -euo pipefail

here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
cd "$(git --no-optional-locks -C "$here" rev-parse --show-toplevel)"

nix-update --flake edstem-cli

version=$(nix eval --raw ".#edstem-cli.version")
pinned=$(sed -n 's/^  version = "\(.*\)";$/\1/p' "$here/esbuild.nix")
if [ -z "$pinned" ]; then
  echo "update.sh: cannot read the esbuild pin from $here/esbuild.nix" >&2
  exit 1
fi

wanted=$(
  curl -fsSL "https://raw.githubusercontent.com/bunizao/edstem-cli/v${version}/package-lock.json" |
    jq -r '.packages["node_modules/esbuild"].version'
)
if [ -z "$wanted" ] || [ "$wanted" = "null" ]; then
  echo "update.sh: no esbuild entry in the package-lock.json of v${version}" >&2
  exit 1
fi

if [ "$pinned" != "$wanted" ]; then
  echo "esbuild pin: $pinned -> $wanted"
  hash=$(
    nix store prefetch-file --unpack --json --hash-type sha256 \
      "https://github.com/evanw/esbuild/archive/v${wanted}.tar.gz" |
      jq -r '.hash'
  )
  sed -i \
    -e "s|^  version = \".*\";$|  version = \"${wanted}\";|" \
    -e "s|^    hash = \"sha256-[^\"]*\";$|    hash = \"${hash}\";|" \
    "$here/esbuild.nix"

  # buildGoModule's vendor hash can only be observed by building, as nix-update does for
  # vendorHash.
  for _ in 1 2 3; do
    out=$(nix build --no-link ".#edstem-cli" 2>&1) && exit 0
    if ! grep -q "esbuild-${wanted}-go-modules.drv" <<<"$out"; then
      printf '%s\n' "$out" >&2
      exit 1
    fi
    got=$(sed -n 's/.*got: *\(sha256-[A-Za-z0-9+/=]*\).*/\1/p' <<<"$out" | head -n 1)
    sed -i "s|^  vendorHash = \"sha256-[^\"]*\";$|  vendorHash = \"${got}\";|" "$here/esbuild.nix"
  done

  echo "update.sh: the vendor hash of esbuild ${wanted} did not settle" >&2
  exit 1
fi

echo "esbuild pin $pinned still matches upstream"
nix build --no-link ".#edstem-cli"
