import argparse
import json
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path
from urllib.request import Request, urlopen

REPO_DIR = Path(__file__).resolve().parent.parent
GO_MODULES = """
{ repo, packageDir, pinsFile }:
let
  flake = builtins.getFlake repo;
  pkgs = flake.inputs.nixpkgs.legacyPackages.${builtins.currentSystem};
  pins = builtins.fromJSON (builtins.readFile (builtins.toPath pinsFile));
in
(pkgs.callPackage (builtins.toPath packageDir) { inherit pins; }).goModules
"""


def run(*args, env=None):
    return subprocess.check_output(args, text=True, cwd=REPO_DIR, env=env).strip()


def require_hash(value):
    if not isinstance(value, str) or not re.fullmatch(
        r"sha256-[A-Za-z0-9+/]{43}=", value
    ):
        raise ValueError(f"Unexpected SHA-256 hash: {value!r}")
    return value


def read_url_json(url, headers=None):
    request = Request(
        url,
        headers={
            "Accept": "application/json",
            "User-Agent": "nix-misc-packages-updater",
            **(headers or {}),
        },
    )
    with urlopen(request, timeout=30) as response:
        return json.load(response)


def latest_release(owner, repo):
    headers = {}
    if token := os.environ.get("GITHUB_TOKEN"):
        headers["Authorization"] = f"Bearer {token}"
    release = read_url_json(
        f"https://api.github.com/repos/{owner}/{repo}/releases/latest", headers
    )
    tag = release["tag_name"]
    if not isinstance(tag, str) or not tag:
        raise ValueError("Expected a non-empty release tag")
    ref = f"refs/tags/{tag}"
    tags = run(
        "git",
        "ls-remote",
        "--exit-code",
        f"https://github.com/{owner}/{repo}.git",
        ref,
        f"{ref}^{{}}",
    ).splitlines()
    refs = {name: rev for rev, name in map(str.split, tags)}
    rev = refs.get(f"{ref}^{{}}", refs.get(ref, ""))
    if not re.fullmatch(r"[0-9a-f]{40}", rev):
        raise ValueError(f"Could not resolve release tag {tag!r} to a commit")
    return tag.removeprefix("v"), rev


def prefetch_source(owner, repo, rev):
    result = json.loads(
        run(
            "nix",
            "store",
            "prefetch-file",
            "--unpack",
            "--name",
            "source",
            "--json",
            f"https://github.com/{owner}/{repo}/archive/{rev}.tar.gz",
        )
    )
    require_hash(result["hash"])
    return result["hash"], Path(result["storePath"])


def prefetch_go_modules(package_dir, pins):
    with tempfile.TemporaryDirectory(prefix=f"{package_dir.name}-") as temporary:
        candidate = Path(temporary) / "pins.json"
        candidate_pins = {**pins, "vendorHash": "sha256-" + "A" * 43 + "="}
        candidate.write_text(json.dumps(candidate_pins) + "\n")
        expression = Path(temporary) / "modules.nix"
        expression.write_text(GO_MODULES)
        arguments = (
            "nix",
            "eval",
            "--impure",
            "--raw",
            "--file",
            str(expression),
            "drvPath",
            "--argstr",
            "repo",
            str(REPO_DIR),
            "--argstr",
            "packageDir",
            str(package_dir),
            "--argstr",
            "pinsFile",
            str(candidate),
        )
        derivation = run(*arguments)
        result = subprocess.run(
            [
                "nix",
                "build",
                "--no-link",
                "--print-out-paths",
                "--log-format",
                "raw",
                f"{derivation}^out",
            ],
            cwd=REPO_DIR,
            check=False,
            text=True,
            capture_output=True,
        )
        # Only accept a mismatch from the requested modules, not a failing source or toolchain.
        mismatch = re.search(
            rf"hash mismatch in fixed-output derivation '{re.escape(derivation)}':\s+"
            rf"specified:\s+\S+\s+got:\s+(sha256-[A-Za-z0-9+/]{{43}}=)",
            result.stderr,
        )
        if result.returncode == 0 or mismatch is None:
            sys.stderr.write(result.stderr)
            raise RuntimeError(
                "Expected a vendor hash mismatch from the Go modules derivation"
            )
        vendor_hash = require_hash(mismatch[1])
        candidate_pins["vendorHash"] = vendor_hash
        candidate.write_text(json.dumps(candidate_pins) + "\n")
        verified = run(*arguments)
        run("nix", "build", "--no-link", "--print-out-paths", f"{verified}^out")
    return vendor_hash


def atomic_write(path, content):
    path = Path(path)
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(
            dir=path.parent, prefix=f".{path.name}.", delete=False
        ) as stream:
            temporary = Path(stream.name)
            stream.write(content)
        temporary.chmod(path.stat().st_mode & 0o777 if path.exists() else 0o644)
        temporary.replace(path)
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)


def write_pins(path, pins):
    atomic_write(path, (json.dumps(pins, indent=2) + "\n").encode())


def update_release(package_dir, owner, repo, prepare):
    parser = argparse.ArgumentParser(
        description=f"Update {package_dir.name} source and dependency pins"
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Refresh hashes even when the release is unchanged",
    )
    args = parser.parse_args()
    pins_file = package_dir / "pins.json"
    current = json.loads(pins_file.read_text())
    version, rev = latest_release(owner, repo)
    if current["version"] == version and current["rev"] == rev and not args.force:
        print(f"{package_dir.name} is up to date at {version}")
        return

    source_hash, source = prefetch_source(owner, repo, rev)
    pins = {"version": version, "rev": rev, "hash": source_hash}
    pins.update(prepare(pins, source))
    write_pins(pins_file, pins)
    print(f"Updated {package_dir.name} {version} at {rev}")
