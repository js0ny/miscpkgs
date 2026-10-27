#!/usr/bin/env python3
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from update_utils import prefetch_go_modules, update_release

PACKAGE_DIR = Path(__file__).resolve().parent


def prepare(pins, _source):
    return {"vendorHash": prefetch_go_modules(PACKAGE_DIR, pins)}


def main():
    update_release(PACKAGE_DIR, "komari-monitor", "komari-agent", prepare)


if __name__ == "__main__":
    main()
