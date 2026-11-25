#!/usr/bin/env python3
import json
import sys
import tomllib
from pathlib import Path

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from update_utils import (
    DEPENDENCY_DERIVATION,
    prefetch_dependency_hash,
    require_hash,
    run,
    update_release,
)

PACKAGE_DIR = Path(__file__).resolve().parent
OWNER = "ShayanAbbas1"
REPO = "dbdelve"


def prepare(pins, source):
    version = pins["version"]
    manifest = tomllib.loads((source / "Cargo.toml").read_text())
    if manifest["workspace"]["package"]["version"] != version:
        raise ValueError("Release tag and Cargo.toml versions differ")

    release_assets = {}
    for arch in ("x86_64", "aarch64"):
        url = (
            f"https://github.com/{OWNER}/{REPO}/releases/download/v{version}/"
            f"{REPO}-{version}-linux-{arch}.tar.gz"
        )
        result = json.loads(run("nix", "store", "prefetch-file", "--json", url))
        release_assets[f"{arch}-linux"] = {"url": url, "hash": require_hash(result["hash"])}

    cargo_hash = prefetch_dependency_hash(
        PACKAGE_DIR,
        {**pins, "releaseAssets": release_assets},
        "cargoHash",
        DEPENDENCY_DERIVATION.replace("__DEPENDENCY__", "dbdelve-src.cargoDeps.vendorStaging"),
        "Expected a cargo vendor hash mismatch",
    )
    return {"cargoHash": cargo_hash, "releaseAssets": release_assets}


if __name__ == "__main__":
    update_release(PACKAGE_DIR, OWNER, REPO, prepare)
