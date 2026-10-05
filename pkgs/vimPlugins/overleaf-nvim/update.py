#!/usr/bin/env python3
import os
import shutil
import subprocess
import tempfile
from pathlib import Path

PACKAGE_DIR = Path(__file__).resolve().parent
REPO_DIR = PACKAGE_DIR.parents[2]


def run(*args, env=None):
    return subprocess.check_output(args, text=True, cwd=REPO_DIR, env=env).strip()


def main():
    system = run("nix", "eval", "--impure", "--raw", "--expr", "builtins.currentSystem")
    package = f"path:.#legacyPackages.{system}.vimPlugins.overleaf-nvim"
    source = Path(run("nix", "build", f"{package}.src", "--no-link", "--print-out-paths"))
    old_hash = run("nix", "eval", "--raw", f"{package}.npmDeps.outputHash")
    package_file = PACKAGE_DIR / "default.nix"
    definition = package_file.read_text()
    hash_field = f'hash = "{old_hash}";'
    if definition.count(hash_field) != 1:
        raise ValueError("Expected exactly one npm dependency hash in default.nix")

    with tempfile.TemporaryDirectory(prefix="overleaf-nvim-") as temporary:
        node_dir = Path(temporary) / "node"
        node_dir.mkdir()
        _ = shutil.copyfile(source / "node/package.json", node_dir / "package.json")
        env = dict(os.environ, npm_config_cache=str(Path(temporary) / "npm-cache"))
        _ = subprocess.run(
            [
                "nix", "shell", "--inputs-from", "path:.", "nixpkgs#nodejs", "nixpkgs#git",
                "--command", "npm", "--prefix", str(node_dir), "install",
                "--package-lock-only", "--ignore-scripts", "--no-audit", "--no-fund",
            ],
            cwd=REPO_DIR,
            env=env,
            check=True,
        )
        lock_file = node_dir / "package-lock.json"
        npm_hash = run(
            "nix", "shell", "--inputs-from", "path:.", "nixpkgs#prefetch-npm-deps",
            "--command", "prefetch-npm-deps", str(lock_file),
            env=dict(os.environ, NPM_FETCHER_VERSION="1"),
        )
        if not npm_hash.startswith("sha256-"):
            raise ValueError(f"Unexpected npm dependency hash: {npm_hash}")
        updated = definition.replace(hash_field, f'hash = "{npm_hash}";')
        _ = (PACKAGE_DIR / "package-lock.json").write_bytes(lock_file.read_bytes())
        _ = package_file.write_text(updated)

    print(f"Updated overleaf-nvim lockfile and npm dependency hash: {npm_hash}")


if __name__ == "__main__":
    main()
