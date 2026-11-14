#!/usr/bin/env python3
import json
import sys
from pathlib import Path

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from update_utils import (
    DEPENDENCY_DERIVATION,
    prefetch_cargo_deps,
    prefetch_dependency_hash,
    update_release,
)

PACKAGE_DIR = Path(__file__).resolve().parent


def prepare(pins, source):
    manifest = json.loads((source / "package.json").read_text())
    if manifest["version"] != pins["version"]:
        raise ValueError("Release tag and package.json versions differ")
    candidate = {**pins, "cargoHash": "sha256-" + "A" * 43 + "="}
    npm_hash = prefetch_dependency_hash(
        PACKAGE_DIR,
        candidate,
        "npmHash",
        DEPENDENCY_DERIVATION.replace("__DEPENDENCY__", "npmDeps"),
        "Expected an npm dependency hash mismatch",
    )
    cargo_hash = prefetch_cargo_deps(PACKAGE_DIR, {**pins, "npmHash": npm_hash})
    return {"npmHash": npm_hash, "cargoHash": cargo_hash}


if __name__ == "__main__":
    update_release(PACKAGE_DIR, "YashwanthKamireddi", "Skykeep", prepare)
