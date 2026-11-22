"""Exercise catalog discovery and its terminal menu without network access."""

import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

sys.dont_write_bytecode = True

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("desk_tests", ROOT / "scripts/test-desk.py")
desk_tests = importlib.util.module_from_spec(spec)
spec.loader.exec_module(desk_tests)


class DiscoveryTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.install = self.root / "Potions home"
        self.cache = self.install / ".registry"
        self.cache.mkdir(parents=True)
        (self.install / "bin").mkdir()
        shutil.copy(ROOT / ".potions/bin/potions", self.install / "bin/potions")
        shutil.copy(ROOT / ".version", self.install)
        self.cli = str(self.install / "bin/potions")
        self.env = dict(os.environ, HOME=str(self.root), POTIONS_HOME=str(self.install),
                        NO_COLOR="1", TERM="xterm-256color")
        subprocess.run(["bash", "-c", 'source "$1/scripts/install-plugin-runtime.sh"; install_plugin_runtime "$1" "$2"',
                        "test", str(ROOT), str(self.install)], env=self.env, check=True,
                       stdout=subprocess.DEVNULL)
        mock_bin = self.root / "bin"
        mock_bin.mkdir()
        # A failed curl is sufficient to exercise normal download/cache handling.
        (mock_bin / "curl").write_text(f"#!{shutil.which('sh')}\nexit 1\n")
        (mock_bin / "curl").chmod(0o755)
        self.env["PATH"] = f"{mock_bin}:{self.env['PATH']}"
        self.entry = dict(name="fixture-navigation", version="1.0.0", author="Fixture",
                          description="Ordinary keyboard navigation", license="MIT",
                          repository="https://github.com/fixture/navigation@v1.0.0",
                          reviewed_commit="a" * 40)

    def catalog(self, entries):
        objects = ",\n".join("    " + json.dumps(item) for item in entries)
        (self.cache / "index.json").write_text('{\n  "plugins": [\n' + objects + '\n  ]\n}\n')
        # Stale cache must remain useful for browsing when the network is down.
        (self.cache / ".timestamp").write_text("1\n")

    def run_cli(self, *args):
        return subprocess.run(["bash", self.cli, "plugin", *args], env=self.env, capture_output=True,
                              text=True, stdin=subprocess.DEVNULL, timeout=10)

    def test_first_run_offline_explains_failure(self):
        for args in (("search",), ("search", "keyboard"), ("info", "fixture-navigation")):
            with self.subTest(args=args):
                result = self.run_cli(*args)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("no cached catalog", result.stderr)
                self.assertIn("potions plugin registry-sync", result.stderr)

    def test_cached_catalog_details_and_no_match(self):
        self.catalog([self.entry])
        for args in (("search",), ("search", "keyboard")):
            result = self.run_cli(*args)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn("  fixture-navigation\n", result.stdout)
            self.assertIn("Using cached registry index", result.stderr)
        result = self.run_cli("search", "absent")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("No plugins found matching: absent", result.stdout)
        result = self.run_cli("info", "fixture-navigation")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn(self.entry["repository"], result.stdout)
        self.assertIn(self.entry["reviewed_commit"], result.stdout)
        self.assertNotIn("Fetching manifest", result.stderr)
        # Offline browsing must never weaken fresh review checks on installs.
        result = self.run_cli("install", "fixture-navigation", "--trust")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("requires current catalog data", result.stdout)
        self.assertFalse((self.install / "plugins/fixture-navigation").exists())

    def test_empty_catalog_and_installed_help(self):
        self.catalog([])
        result = self.run_cli("search")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("No plugins are currently listed", result.stdout)
        result = self.run_cli("help")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("potions plugin search", result.stdout)
        self.assertNotIn("./plugins.sh", result.stdout)
        self.assertIn(str(self.install / "Potionfile"), result.stdout)

    def test_menu_browse_search_and_details(self):
        self.catalog([self.entry])
        term = desk_tests.Terminal(["bash", self.cli, "plugin", "menu"], self.root, self.env, (28, 100))
        try:
            term.until(b"9 Inspect plugin details")
            term.send(b"7\r")
            term.until(b"  fixture-navigation")
            term.until(b"9 Inspect plugin details")
            term.send(b"8\r")
            term.until(b"Search query> ")
            term.send(b"keyboard\r")
            term.until(b"  fixture-navigation")
            term.until(b"9 Inspect plugin details")
            term.send(b"9\r")
            term.until(b"Plugin info> ")
            term.send(b"fixture-navigation\r")
            term.until(self.entry["reviewed_commit"].encode())
            term.until(b"9 Inspect plugin details")
            term.send(b"q\r")
            self.assertEqual(term.process.wait(timeout=5), 0)
        finally:
            term.close()


if __name__ == "__main__":
    unittest.main(verbosity=2)
