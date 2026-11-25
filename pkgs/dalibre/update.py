#!/usr/bin/env python3
import json
import sys
from pathlib import Path

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from update_utils import prefetch_go_modules, update_release

PACKAGE_DIR = Path(__file__).resolve().parent


def prepare(pins, source):
    manifest = json.loads((source / "cmd" / "dalibre" / "mygo.json").read_text())
    if manifest["version"] != pins["version"]:
        raise ValueError("Release tag and mygo.json versions differ")
    return {"vendorHash": prefetch_go_modules(PACKAGE_DIR, pins)}


if __name__ == "__main__":
    update_release(PACKAGE_DIR, "djyde", "dalibre", prepare)
