#!/usr/bin/env python3
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))
from update_utils import update_release

PACKAGE_DIR = Path(__file__).resolve().parent


def main():
    update_release(PACKAGE_DIR, "dirichy", "flash-any.nvim", lambda _pins, _source: {}, snapshot=True)


if __name__ == "__main__":
    main()
