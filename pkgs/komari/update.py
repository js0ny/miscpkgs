#!/usr/bin/env python3
import argparse
import json
import os
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from update_utils import (
    latest_release,
    prefetch_go_modules,
    prefetch_source,
    require_hash,
    run,
    write_pins,
)

PACKAGE_DIR = Path(__file__).resolve().parent


def main():
    parser = argparse.ArgumentParser(
        description="Update Komari backend and frontend pins"
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Refresh hashes even when releases are unchanged",
    )
    args = parser.parse_args()
    pins_file = PACKAGE_DIR / "pins.json"
    current = json.loads(pins_file.read_text())
    version, rev = latest_release("komari-monitor", "komari")
    frontend_version, frontend_rev = latest_release("komari-monitor", "komari-web")
    backend_changed = args.force or (version, rev) != (
        current["version"],
        current["rev"],
    )
    frontend_changed = args.force or (frontend_version, frontend_rev) != (
        current["frontend"]["version"],
        current["frontend"]["rev"],
    )
    if not backend_changed and not frontend_changed:
        print(f"komari {version} and frontend {frontend_version} are up to date")
        return

    pins = {**current, "frontend": dict(current["frontend"])}
    if frontend_changed:
        source_hash, source = prefetch_source(
            "komari-monitor", "komari-web", frontend_rev
        )
        npm_hash = run(
            "nix",
            "shell",
            "--inputs-from",
            "path:.",
            "nixpkgs#prefetch-npm-deps",
            "--command",
            "prefetch-npm-deps",
            str(source / "package-lock.json"),
            env=dict(os.environ, NPM_FETCHER_VERSION="1"),
        )
        pins["frontend"] = {
            "version": frontend_version,
            "rev": frontend_rev,
            "hash": source_hash,
            "npmDepsHash": require_hash(npm_hash),
        }
    if backend_changed:
        source_hash, _ = prefetch_source("komari-monitor", "komari", rev)
        pins.update(version=version, rev=rev, hash=source_hash)
        pins["vendorHash"] = prefetch_go_modules(PACKAGE_DIR, pins)
    write_pins(pins_file, pins)
    print(
        f"Updated komari {pins['version']} at {pins['rev']}; frontend {pins['frontend']['version']} at {pins['frontend']['rev']}"
    )


if __name__ == "__main__":
    main()
