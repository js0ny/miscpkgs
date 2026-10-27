#!/usr/bin/env bash
set -euo pipefail

here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
file="$here/default.nix"
repo="yuk1ty/herdr-spreader"

latest_tag=$(curl -fsSL "https://api.github.com/repos/$repo/releases/latest" | jq -r '.tag_name')
if [[ -z "$latest_tag" || "$latest_tag" == "null" || "$latest_tag" != v* ]]; then
  echo "update.sh: unable to determine the latest stable release tag" >&2
  exit 1
fi

version=${latest_tag#v}
rev=$(git ls-remote "https://github.com/$repo.git" "refs/tags/$latest_tag^{}" | awk 'NR == 1 { print $1 }')
if [[ ! "$rev" =~ ^[0-9a-f]{40}$ ]]; then
  echo "update.sh: unable to resolve $latest_tag to a commit" >&2
  exit 1
fi

hash=$(nix store prefetch-file --unpack --json --hash-type sha256 \
  "https://github.com/$repo/archive/refs/tags/$latest_tag.tar.gz" | jq -r '.hash')
if [[ -z "$hash" || "$hash" == "null" ]]; then
  echo "update.sh: unable to calculate the source hash for $latest_tag" >&2
  exit 1
fi

sed -i \
  -e "s|^  version = \"[^\"]*\";$|  version = \"$version\";|" \
  -e "s|^    rev = \"[0-9a-f]*\";$|    rev = \"$rev\";|" \
  -e "s|^    hash = \"sha256-[^\"]*\";$|    hash = \"$hash\";|" \
  "$file"

echo "Updated $repo to $latest_tag ($rev)"
