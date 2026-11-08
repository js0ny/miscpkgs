#!/usr/bin/env python3
import sys
from pathlib import Path
import tomllib

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from update_utils import prefetch_cargo_deps, update_release

PACKAGE_DIR = Path(__file__).resolve().parent


def prepare(pins, source):
    manifest = tomllib.loads((source / "Cargo.toml").read_text())
    if manifest["package"]["version"] != pins["version"]:
        raise ValueError("Release tag and Cargo.toml versions differ")
    return {"cargoHash": prefetch_cargo_deps(PACKAGE_DIR, pins)}


if __name__ == "__main__":
    update_release(PACKAGE_DIR, "shotori-screenshot", "shotori", prepare)
