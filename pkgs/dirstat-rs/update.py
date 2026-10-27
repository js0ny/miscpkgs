#!/usr/bin/env python3
import sys
import tomllib
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from update_utils import update_release

PACKAGE_DIR = Path(__file__).resolve().parent


def prepare(pins, source):
    manifest = tomllib.loads((source / "Cargo.toml").read_text())
    if manifest["package"]["version"] != pins["version"]:
        raise ValueError("Release tag and Cargo.toml versions differ")
    lock = tomllib.loads((source / "Cargo.lock").read_text())
    if any(package.get("source", "").startswith("git+") for package in lock["package"]):
        raise ValueError(
            "Git dependencies require cargoLock.outputHashes in default.nix"
        )
    return {}


def main():
    update_release(PACKAGE_DIR, "scullionw", "dirstat-rs", prepare)


if __name__ == "__main__":
    main()
