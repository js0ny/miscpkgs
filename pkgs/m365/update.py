#!/usr/bin/env python3
import argparse
from concurrent.futures import ThreadPoolExecutor
import json
import os
from pathlib import Path
import subprocess
import tempfile
from urllib.parse import quote
from urllib.request import Request, urlopen


PACKAGE_DIR = Path(__file__).resolve().parent
REPO_DIR = PACKAGE_DIR.parent.parent
UPSTREAM = "https://github.com/pnp/cli-microsoft365.git"


def run(*args, env=None):
    return subprocess.check_output(args, text=True, cwd=REPO_DIR, env=env).strip()


def resolve_package(item):
    path, entry = item
    name = entry.get("name", path.rsplit("node_modules/", 1)[-1])
    url = f"https://registry.npmjs.org/{quote(name, safe='')}/{quote(entry['version'], safe='')}"
    with urlopen(Request(url, headers={"Accept": "application/json"}), timeout=30) as response:
        metadata = json.load(response)
    if metadata["name"] != name or metadata["version"] != entry["version"]:
        raise ValueError(f"Unexpected registry metadata for {name}@{entry['version']}")
    dist = metadata["dist"]
    return path, dist["tarball"], dist["integrity"]


def main():
    parser = argparse.ArgumentParser(description="Update the m365 source and Nix npm lockfile")
    parser.add_argument("--force", action="store_true", help="Refresh hashes even when HEAD is unchanged")
    args = parser.parse_args()

    source_file = PACKAGE_DIR / "source.json"
    current = json.loads(source_file.read_text())
    rev = run("git", "ls-remote", UPSTREAM, "HEAD").split()[0]
    if rev == current["rev"] and not args.force:
        print(f"m365 is up to date at {rev}")
        return

    archive = f"https://github.com/pnp/cli-microsoft365/archive/{rev}.tar.gz"
    prefetched = json.loads(run("nix", "store", "prefetch-file", "--unpack", "--json", archive))
    upstream = Path(prefetched["storePath"])
    package = json.loads((upstream / "package.json").read_text())
    lock = json.loads((upstream / "npm-shrinkwrap.json").read_text())
    if lock["version"] != package["version"] or lock["packages"][""]["version"] != package["version"]:
        raise ValueError("Upstream package.json and npm-shrinkwrap.json versions differ")

    missing = [(path, entry) for path, entry in lock["packages"].items() if path and not entry.get("resolved")]
    with ThreadPoolExecutor(max_workers=16) as pool:
        for path, resolved, integrity in pool.map(resolve_package, missing):
            fields = list(lock["packages"][path].items())
            version = next(index for index, (key, _) in enumerate(fields) if key == "version")
            fields[version + 1:version + 1] = [("resolved", resolved), ("integrity", integrity)]
            lock["packages"][path] = dict(fields)

    with tempfile.TemporaryDirectory() as temporary:
        lock_file = Path(temporary) / "npm-shrinkwrap.json"
        lock_file.write_text(json.dumps(lock, ensure_ascii=False, indent=2) + "\n")
        env = dict(os.environ, NPM_FETCHER_VERSION="2")
        npm_hash = run(
            "nix", "shell", "--inputs-from", "path:.", "nixpkgs#prefetch-npm-deps",
            "--command", "prefetch-npm-deps", str(lock_file), env=env,
        )
        if not npm_hash.startswith("sha256-"):
            raise ValueError(f"Unexpected npm dependency hash: {npm_hash}")
        (PACKAGE_DIR / "npm-shrinkwrap.json").write_bytes(lock_file.read_bytes())

    source_file.write_text(json.dumps({
        "version": package["version"],
        "rev": rev,
        "hash": prefetched["hash"],
        "npmDepsHash": npm_hash,
    }, indent=2) + "\n")
    print(f"Updated m365 {package['version']} at {rev}; resolved {len(missing)} npm packages")


if __name__ == "__main__":
    main()
