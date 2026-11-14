#!/usr/bin/env python3
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from update_utils import (
    DEPENDENCY_DERIVATION,
    atomic_write,
    prefetch_dependency_hash,
    prefetch_go_modules,
    update_release,
)

PACKAGE_DIR = Path(__file__).resolve().parent


def prepare(pins, source):
    with tempfile.TemporaryDirectory(prefix="pixivbiu-update-") as directory:
        temporary = Path(directory)
        package = temporary / "package"
        package.mkdir()
        shutil.copy2(PACKAGE_DIR / "default.nix", package / "default.nix")
        frontend = temporary / "frontend"
        frontend.mkdir()
        shutil.copy2(source / "frontend/package.json", frontend / "package.json")
        subprocess.run(
            [
                "nix", "shell", "--no-write-lock-file", "--inputs-from", ".",
                "nixpkgs#nodejs", "--command", "npm", "install",
                "--package-lock-only", "--ignore-scripts", "--no-audit",
                "--no-fund", "--legacy-peer-deps", "--cache", str(temporary / "npm-cache"),
                "--prefix", str(frontend),
            ],
            cwd=PACKAGE_DIR.parent.parent,
            check=True,
        )
        lock = (frontend / "package-lock.json").read_bytes()
        (package / "package-lock.json").write_bytes(lock)
        candidate = {**pins, "vendorHash": "sha256-" + "A" * 43 + "="}
        npm_hash = prefetch_dependency_hash(
            package, candidate, "npmHash",
            DEPENDENCY_DERIVATION.replace("__DEPENDENCY__", "npmDeps"),
            "Expected an npm dependency hash mismatch",
        )
        vendor_hash = prefetch_go_modules(package, {**pins, "npmHash": npm_hash})
        atomic_write(PACKAGE_DIR / "package-lock.json", lock)
        return {"npmHash": npm_hash, "vendorHash": vendor_hash}


if __name__ == "__main__":
    update_release(PACKAGE_DIR, "txperl", "PixivBiu", prepare)
