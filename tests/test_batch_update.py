import contextlib
import importlib.machinery
import importlib.util
import io
import json
import os
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

REPO_DIR = Path(__file__).resolve().parents[1]
loader = importlib.machinery.SourceFileLoader(
    "batch_update", str(REPO_DIR / "helper" / "update")
)
spec = importlib.util.spec_from_loader(loader.name, loader)
batch_update = importlib.util.module_from_spec(spec)
loader.exec_module(batch_update)


class BatchUpdateTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name).resolve()
        self.manifest = {}
        for name in ("alpha", "nested/beta", "name with spaces"):
            script = self.root / "pkgs" / name / "update.py"
            script.parent.mkdir(parents=True)
            script.write_text("raise SystemExit(0)\n")
            self.manifest[Path(name).name] = script.relative_to(self.root).as_posix()
        self.manifest_file = self.root / "manifest.json"
        self.manifest_file.write_text(json.dumps(self.manifest))
        self.enterContext(patch.object(batch_update, "REPO_DIR", self.root))
        self.stdout = self.enterContext(contextlib.redirect_stdout(io.StringIO()))
        self.stderr = self.enterContext(contextlib.redirect_stderr(io.StringIO()))

    def run_batch(self, *arguments):
        return batch_update.main(["--manifest", str(self.manifest_file), *arguments])

    def test_default_manifest_is_evaluated_from_the_checkout_without_lock_updates(self):
        with patch.object(
            batch_update.subprocess,
            "check_output",
            return_value=json.dumps(self.manifest),
        ) as evaluate:
            result = batch_update.load_manifest(None)
        self.assertEqual(set(result), set(self.manifest))
        self.assertEqual(
            evaluate.call_args.args[0],
            [
                "nix",
                "eval",
                "--json",
                "--no-write-lock-file",
                f"path:{self.root}#updateManifest",
            ],
        )
        self.assertEqual(evaluate.call_args.kwargs["cwd"], self.root)

    def test_runs_all_manifest_entries_in_name_order(self):
        with patch.object(
            batch_update.subprocess,
            "run",
            return_value=subprocess.CompletedProcess([], 0),
        ) as run:
            self.assertEqual(self.run_batch(), 0)
        self.assertEqual(
            [call.args[0] for call in run.call_args_list],
            [
                [sys.executable, str(self.root / self.manifest[name])]
                for name in sorted(self.manifest)
            ],
        )
        for call in run.call_args_list:
            self.assertEqual(call.kwargs, {"cwd": self.root, "check": False})
        self.assertIn("3 succeeded, 0 failed", self.stdout.getvalue())

    def test_selects_deduplicates_and_excludes_packages(self):
        with patch.object(
            batch_update.subprocess,
            "run",
            return_value=subprocess.CompletedProcess([], 0),
        ) as run:
            self.assertEqual(
                self.run_batch("beta", "--exclude", "alpha", "alpha", "beta"), 0
            )
        run.assert_called_once_with(
            [sys.executable, str(self.root / self.manifest["beta"])],
            cwd=self.root,
            check=False,
        )

    def test_list_and_dry_run_do_not_execute_scripts(self):
        for option in ("--list", "--dry-run"):
            with (
                self.subTest(option=option),
                patch.object(batch_update.subprocess, "run") as run,
            ):
                self.assertEqual(self.run_batch(option, "beta"), 0)
                run.assert_not_called()
        self.assertIn("beta\tpkgs/nested/beta/update.py", self.stdout.getvalue())
        self.assertNotIn("succeeded", self.stdout.getvalue())

    def test_unknown_names_are_rejected_before_running_anything(self):
        for arguments in (("unknown",), ("--exclude", "unknown")):
            with (
                self.subTest(arguments=arguments),
                patch.object(batch_update.subprocess, "run") as run,
                self.assertRaises(SystemExit) as error,
            ):
                self.run_batch(*arguments)
            self.assertEqual(error.exception.code, 2)
            run.assert_not_called()

    def test_failures_do_not_stop_other_updaters_and_return_non_zero(self):
        with patch.object(
            batch_update.subprocess,
            "run",
            side_effect=[
                subprocess.CompletedProcess([], 9),
                subprocess.CompletedProcess([], 0),
            ],
        ) as run:
            self.assertEqual(self.run_batch("alpha", "beta"), 1)
        self.assertEqual(run.call_count, 2)
        self.assertIn("1 succeeded, 1 failed", self.stdout.getvalue())
        self.assertIn("Failed: alpha", self.stderr.getvalue())
        self.assertIn("status 9", self.stderr.getvalue())

    def test_spawn_errors_do_not_stop_other_updaters(self):
        with patch.object(
            batch_update.subprocess,
            "run",
            side_effect=[
                OSError("Cannot start updater"),
                subprocess.CompletedProcess([], 0),
            ],
        ) as run:
            self.assertEqual(self.run_batch("alpha", "beta"), 1)
        self.assertEqual(run.call_count, 2)
        self.assertIn("Cannot start updater", self.stderr.getvalue())

    def test_interrupt_does_not_start_further_updaters(self):
        with (
            patch.object(
                batch_update.subprocess, "run", side_effect=KeyboardInterrupt
            ) as run,
            self.assertRaises(KeyboardInterrupt),
        ):
            self.run_batch("alpha", "beta")
        self.assertEqual(run.call_count, 1)

    def test_rejects_escaping_absolute_missing_and_non_updater_paths(self):
        candidates = [
            "../outside/update.py",
            str(self.root / self.manifest["alpha"]),
            "pkgs/missing/update.py",
            "manifest.json",
        ]
        for candidate in candidates:
            with self.subTest(candidate=candidate):
                self.manifest_file.write_text(json.dumps({"alpha": candidate}))
                with (
                    patch.object(batch_update.subprocess, "run") as run,
                    self.assertRaises(SystemExit),
                ):
                    self.run_batch()
                run.assert_not_called()

    def test_rejects_symlinks_leaving_the_checkout(self):
        with tempfile.TemporaryDirectory() as outside:
            script = Path(outside) / "update.py"
            script.write_text("raise SystemExit(0)\n")
            (self.root / "linked").symlink_to(outside, target_is_directory=True)
            self.manifest_file.write_text(json.dumps({"outside": "linked/update.py"}))
            with self.assertRaisesRegex(ValueError, "Invalid updater path"):
                batch_update.load_manifest(self.manifest_file)

    def test_invalid_manifest_does_not_execute_anything(self):
        for content in (
            "not json",
            "[]",
            '{"alpha": null}',
            '{"": "pkgs/alpha/update.py"}',
        ):
            with self.subTest(content=content):
                self.manifest_file.write_text(content)
                with (
                    patch.object(batch_update.subprocess, "run") as run,
                    self.assertRaises(SystemExit),
                ):
                    self.run_batch()
                run.assert_not_called()

    def test_manifest_evaluation_failure_does_not_start_updaters(self):
        with (
            patch.object(
                batch_update.subprocess,
                "check_output",
                side_effect=subprocess.CalledProcessError(1, ["nix"]),
            ),
            patch.object(batch_update.subprocess, "run") as run,
            self.assertRaises(SystemExit) as error,
        ):
            batch_update.main([])
        self.assertEqual(error.exception.code, 2)
        run.assert_not_called()

    def test_empty_manifest_is_successful(self):
        self.manifest_file.write_text("{}")
        with patch.object(batch_update.subprocess, "run") as run:
            self.assertEqual(self.run_batch(), 0)
        run.assert_not_called()
        self.assertIn("No packages selected", self.stdout.getvalue())

    def test_real_cli_runs_each_script_in_the_checkout_and_collects_failures(self):
        helper = self.root / "helper"
        helper.mkdir()
        shutil.copy2(REPO_DIR / "helper" / "update", helper / "update")
        for name, status in (("alpha", 3), ("beta", 0)):
            script = self.root / self.manifest[name]
            script.write_text(
                "from pathlib import Path\n"
                f"with Path('runs.txt').open('a') as stream:\n    stream.write({name!r} + '\\n')\n"
                f"raise SystemExit({status})\n"
            )
        result = subprocess.run(
            [
                "update",
                "--manifest",
                str(self.manifest_file),
                "alpha",
                "beta",
            ],
            cwd=self.root.parent,
            env={**os.environ, "PATH": f"{helper}{os.pathsep}{os.environ['PATH']}"},
            text=True,
            capture_output=True,
            check=False,
        )
        self.assertEqual(result.returncode, 1, result.stderr)
        self.assertEqual((self.root / "runs.txt").read_text(), "alpha\nbeta\n")
        self.assertIn("1 succeeded, 1 failed", result.stdout)
        self.assertIn("Failed: alpha", result.stderr)


if __name__ == "__main__":
    unittest.main()
