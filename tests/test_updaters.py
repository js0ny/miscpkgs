import contextlib
import importlib.util
import io
import json
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

REPO_DIR = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO_DIR / "pkgs"))
import update_utils


def load_updater(package):
    spec = importlib.util.spec_from_file_location(
        package, REPO_DIR / "pkgs" / package / "update.py"
    )
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


dirstat = load_updater("dirstat-rs")
komari = load_updater("komari-agent")
m365 = load_updater("m365")
SOURCE_HASH = "sha256-" + "A" * 43 + "="
DEPENDENCY_HASH = "sha256-" + "B" * 43 + "="
REV = "a" * 40


class UpdaterTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.package = self.root / "example"
        self.package.mkdir()
        self.pins_file = self.package / "pins.json"
        self.current = {"version": "1.0.0", "rev": REV, "hash": SOURCE_HASH}
        update_utils.write_pins(self.pins_file, self.current)
        self.original = self.pins_file.read_bytes()
        self.stdout = contextlib.redirect_stdout(io.StringIO())
        self.stdout.__enter__()
        self.addCleanup(self.stdout.__exit__, None, None, None)

    def test_release_resolves_annotated_tag_and_uses_github_token(self):
        with (
            patch.dict(os.environ, {"GITHUB_TOKEN": "test-token"}),
            patch.object(
                update_utils, "read_url_json", return_value={"tag_name": "v1.0.0"}
            ) as request,
            patch.object(
                update_utils,
                "run",
                return_value=f"{'b' * 40}\trefs/tags/v1.0.0\n{REV}\trefs/tags/v1.0.0^{{}}",
            ),
        ):
            self.assertEqual(
                update_utils.latest_release("owner", "repo"), ("1.0.0", REV)
            )
            self.assertEqual(
                request.call_args.args[1], {"Authorization": "Bearer test-token"}
            )

    def test_release_resolves_lightweight_tag_without_token(self):
        with (
            patch.dict(os.environ, {}, clear=True),
            patch.object(
                update_utils, "read_url_json", return_value={"tag_name": "1.0.0"}
            ) as request,
            patch.object(update_utils, "run", return_value=f"{REV}\trefs/tags/1.0.0"),
        ):
            self.assertEqual(
                update_utils.latest_release("owner", "repo"), ("1.0.0", REV)
            )
            self.assertEqual(request.call_args.args[1], {})

    def test_release_rejects_missing_commit(self):
        with (
            patch.object(
                update_utils, "read_url_json", return_value={"tag_name": "v1.0.0"}
            ),
            patch.object(update_utils, "run", return_value=""),
            self.assertRaisesRegex(ValueError, "Could not resolve"),
        ):
            update_utils.latest_release("owner", "repo")

    def test_unchanged_release_does_not_fetch_or_write(self):
        with (
            patch.object(sys, "argv", ["update.py"]),
            patch.object(update_utils, "latest_release", return_value=("1.0.0", REV)),
            patch.object(update_utils, "prefetch_source") as prefetch,
        ):
            update_utils.update_release(
                self.package,
                "owner",
                "repo",
                lambda *_: self.fail("Unexpected preparation"),
            )
        prefetch.assert_not_called()
        self.assertEqual(self.pins_file.read_bytes(), self.original)

    def test_force_refreshes_source_and_dependency_pins(self):
        with (
            patch.object(sys, "argv", ["update.py", "--force"]),
            patch.object(update_utils, "latest_release", return_value=("1.0.0", REV)),
            patch.object(
                update_utils, "prefetch_source", return_value=(SOURCE_HASH, self.root)
            ),
        ):
            update_utils.update_release(
                self.package,
                "owner",
                "repo",
                lambda *_: {"vendorHash": DEPENDENCY_HASH},
            )
        self.assertEqual(
            json.loads(self.pins_file.read_text()),
            {**self.current, "vendorHash": DEPENDENCY_HASH},
        )
        self.assertEqual(list(self.package.iterdir()), [self.pins_file])

    def test_failed_preparation_preserves_pins(self):
        def fail(*_):
            raise RuntimeError("Dependency fetch failed")

        with (
            patch.object(sys, "argv", ["update.py"]),
            patch.object(
                update_utils, "latest_release", return_value=("2.0.0", "b" * 40)
            ),
            patch.object(
                update_utils, "prefetch_source", return_value=(SOURCE_HASH, self.root)
            ),
            self.assertRaisesRegex(RuntimeError, "Dependency fetch failed"),
        ):
            update_utils.update_release(self.package, "owner", "repo", fail)
        self.assertEqual(self.pins_file.read_bytes(), self.original)

    def test_atomic_write_cleans_up_after_failed_replacement(self):
        with (
            patch.object(Path, "replace", side_effect=OSError("Failed replacement")),
            self.assertRaises(OSError),
        ):
            update_utils.write_pins(self.pins_file, {})
        self.assertEqual(self.pins_file.read_bytes(), self.original)
        self.assertEqual(list(self.package.iterdir()), [self.pins_file])

    def test_source_prefetch_checks_hash_and_uses_commit_archive(self):
        with patch.object(
            update_utils,
            "run",
            return_value=json.dumps({"hash": SOURCE_HASH, "storePath": str(self.root)}),
        ) as run:
            self.assertEqual(
                update_utils.prefetch_source("owner", "repo", REV),
                (SOURCE_HASH, self.root),
            )
            self.assertEqual(
                run.call_args.args[-1],
                f"https://github.com/owner/repo/archive/{REV}.tar.gz",
            )
        for value in (None, "sha256-short", "sha512-" + "A" * 43 + "="):
            with self.subTest(value=value), self.assertRaises(ValueError):
                update_utils.require_hash(value)

    def test_rust_uses_committed_cargo_lock(self):
        (self.root / "Cargo.toml").write_text('[package]\nversion = "1.0.0"\n')
        (self.root / "Cargo.lock").write_text(
            '[[package]]\nname = "example"\nsource = "registry+https://example.org"\n'
        )
        self.assertEqual(dirstat.prepare(self.current, self.root), {})
        (self.root / "Cargo.lock").write_text(
            '[[package]]\nname = "example"\nsource = "git+https://example.org"\n'
        )
        with self.assertRaisesRegex(ValueError, "cargoLock.outputHashes"):
            dirstat.prepare(self.current, self.root)

    def test_rust_rejects_version_mismatch(self):
        (self.root / "Cargo.toml").write_text('[package]\nversion = "2.0.0"\n')
        with self.assertRaisesRegex(ValueError, "versions differ"):
            dirstat.prepare(self.current, self.root)

    def test_go_prefetch_verifies_computed_hash(self):
        derivation = "/nix/store/example-go-modules.drv"
        candidate_hashes = []

        def run(*args):
            if args[1] == "eval":
                candidate_hashes.append(
                    json.loads(Path(args[-1]).read_text())["vendorHash"]
                )
                return derivation
            return "/nix/store/verified-go-modules"

        mismatch = f"error: hash mismatch in fixed-output derivation '{derivation}':\n  specified: {SOURCE_HASH}\n  got: {DEPENDENCY_HASH}\n"
        with (
            patch.object(update_utils, "run", side_effect=run) as commands,
            patch.object(
                update_utils.subprocess,
                "run",
                return_value=subprocess.CompletedProcess([], 1, "", mismatch),
            ),
        ):
            self.assertEqual(
                komari.prepare(self.current, self.root), {"vendorHash": DEPENDENCY_HASH}
            )
        self.assertEqual(candidate_hashes, [SOURCE_HASH, DEPENDENCY_HASH])
        self.assertEqual(commands.call_args.args[-1], f"{derivation}^out")
        self.assertEqual(self.pins_file.read_bytes(), self.original)

    def test_go_does_not_accept_another_derivations_hash_or_network_failure(self):
        derivation = "/nix/store/example-go-modules.drv"
        failures = [
            "Network error",
            f"hash mismatch in fixed-output derivation '/nix/store/source.drv':\n specified: {SOURCE_HASH}\n got: {DEPENDENCY_HASH}",
        ]
        for message in failures:
            with (
                self.subTest(message=message),
                patch.object(update_utils, "run", return_value=derivation),
                patch.object(
                    update_utils.subprocess,
                    "run",
                    return_value=subprocess.CompletedProcess([], 1, "", message),
                ),
                contextlib.redirect_stderr(io.StringIO()),
                self.assertRaisesRegex(RuntimeError, "Expected a vendor hash mismatch"),
            ):
                komari.prepare(self.current, self.root)

    def prepare_m365(self):
        upstream = self.root / "upstream"
        upstream.mkdir()
        (upstream / "package.json").write_text(json.dumps({"version": "2.0.0"}))
        lock = {
            "version": "2.0.0",
            "lockfileVersion": 3,
            "packages": {
                "": {"version": "2.0.0"},
                "node_modules/@scope/example": {"version": "1.0.0"},
                "node_modules/existing": {
                    "version": "1.0.0",
                    "resolved": "https://existing",
                    "integrity": "sha512-existing",
                },
            },
        }
        (upstream / "npm-shrinkwrap.json").write_text(json.dumps(lock))
        (self.package / "npm-shrinkwrap.json").write_text("original lockfile\n")
        return upstream

    def test_m365_repairs_lockfile_and_writes_pins(self):
        upstream = self.prepare_m365()

        def run(*args, env=None):
            if args[0] == "git":
                return "b" * 40 + "\tHEAD"
            self.assertEqual(env["NPM_FETCHER_VERSION"], "2")
            lock = json.loads(Path(args[-1]).read_text())
            self.assertEqual(
                lock["packages"]["node_modules/@scope/example"]["resolved"],
                "https://registry/example.tgz",
            )
            return DEPENDENCY_HASH

        metadata = {
            "name": "@scope/example",
            "version": "1.0.0",
            "dist": {
                "tarball": "https://registry/example.tgz",
                "integrity": "sha512-example",
            },
        }
        with (
            patch.object(sys, "argv", ["update.py"]),
            patch.object(m365, "PACKAGE_DIR", self.package),
            patch.object(m365, "run", side_effect=run),
            patch.object(m365, "prefetch_source", return_value=(SOURCE_HASH, upstream)),
            patch.object(m365, "read_url_json", return_value=metadata) as registry,
        ):
            m365.main()
        self.assertIn("%40scope%2Fexample", registry.call_args.args[0])
        self.assertEqual(
            json.loads(self.pins_file.read_text()),
            {
                "version": "2.0.0",
                "rev": "b" * 40,
                "hash": SOURCE_HASH,
                "npmDepsHash": DEPENDENCY_HASH,
            },
        )
        lock = json.loads((self.package / "npm-shrinkwrap.json").read_text())
        self.assertEqual(
            lock["packages"]["node_modules/existing"]["resolved"], "https://existing"
        )
        self.assertEqual(
            lock["packages"]["node_modules/@scope/example"]["integrity"],
            "sha512-example",
        )

    def test_m365_failure_preserves_both_files(self):
        upstream = self.prepare_m365()
        with (
            patch.object(sys, "argv", ["update.py"]),
            patch.object(m365, "PACKAGE_DIR", self.package),
            patch.object(
                m365, "run", side_effect=["b" * 40 + "\tHEAD", "invalid hash"]
            ),
            patch.object(m365, "prefetch_source", return_value=(SOURCE_HASH, upstream)),
            patch.object(
                m365,
                "resolve_package",
                return_value=(
                    "node_modules/@scope/example",
                    "https://registry/example.tgz",
                    "sha512-example",
                ),
            ),
            self.assertRaisesRegex(ValueError, "Unexpected SHA-256"),
        ):
            m365.main()
        self.assertEqual(self.pins_file.read_bytes(), self.original)
        self.assertEqual(
            (self.package / "npm-shrinkwrap.json").read_text(), "original lockfile\n"
        )

    def test_m365_unchanged_head_skips_prefetch(self):
        with (
            patch.object(sys, "argv", ["update.py"]),
            patch.object(m365, "PACKAGE_DIR", self.package),
            patch.object(m365, "run", return_value=REV + "\tHEAD"),
            patch.object(m365, "prefetch_source") as prefetch,
        ):
            m365.main()
        prefetch.assert_not_called()
        self.assertEqual(self.pins_file.read_bytes(), self.original)


if __name__ == "__main__":
    unittest.main()
