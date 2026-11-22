"""Exercise the installed CLI in a real terminal, including editor handoff."""

import contextlib
from concurrent.futures import ThreadPoolExecutor
import fcntl
import os
from pathlib import Path
import pty
import select
import shutil
import signal
import struct
import subprocess
import tempfile
import termios
import time
import unittest


ROOT = Path(__file__).resolve().parents[1]
ENTER_SCREEN = b"\x1b[?1049h"
LEAVE_SCREEN = b"\x1b[?1049l"


class Terminal:
    def __init__(self, argv, cwd, env, size):
        self.master, self.slave = pty.openpty()
        self.resize(*size)
        self.original = self.settings()
        self.buffer = b""
        self.process = subprocess.Popen(
            argv, cwd=cwd, env=env, stdin=self.slave, stdout=self.slave,
            stderr=self.slave, preexec_fn=os.setpgrp,
        )

    def resize(self, rows, columns):
        size = struct.pack("HHHH", rows, columns, 0, 0)
        fcntl.ioctl(self.slave, termios.TIOCSWINSZ, size)

    def send(self, keys):
        os.write(self.master, keys)

    def settings(self):
        attrs = termios.tcgetattr(self.slave)
        # BSD sets transient PENDIN when returning to canonical input.
        attrs[3] &= ~getattr(termios, "PENDIN", 0)
        return attrs

    def until(self, token):
        end = time.monotonic() + 5
        while token not in self.buffer:
            timeout = max(0, end - time.monotonic())
            if not select.select([self.master], [], [], timeout)[0]:
                raise AssertionError(f"Missing {token!r}. Terminal tail: {self.buffer[-1200:]!r}")
            self.buffer += os.read(self.master, 65536)
        before, self.buffer = self.buffer.split(token, 1)
        return before

    def close(self):
        os.close(self.master)
        os.close(self.slave)
        if self.process.poll() is None:
            self.process.kill()
        self.process.wait(timeout=5)


class DeskTests(unittest.TestCase):
    def setUp(self):
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        self.home = Path(temp.name)
        self.install = self.home / ".potions"
        # Invoke a deployed CLI with no source checkout next to it.
        for directory in ("bin", "lib", "zellij"):
            shutil.copytree(ROOT / ".potions" / directory, self.install / directory)
        shutil.copy(ROOT / ".version", self.install)
        self.cli = str(self.install / "bin" / "potions")
        self.project = self.home / "project with spaces"
        self.project.mkdir()
        self.env = dict(os.environ, HOME=str(self.home), POTIONS_HOME=str(self.install),
                        TERM="xterm-256color", LC_ALL="C", NO_COLOR="1", ZELLIJ="")

    @contextlib.contextmanager
    def terminal(self, *args, size=(24, 80), **overrides):
        term = Terminal(["bash", self.cli, *args], self.project, dict(self.env, **overrides), size)
        try:
            yield term
        finally:
            term.close()

    def test_printable_entry_points(self):
        def output(*args):
            return subprocess.check_output(["bash", self.cli, *args], env=self.env,
                                           stdin=subprocess.DEVNULL, timeout=5)
        self.assertEqual(output(), output("help"))
        reference = output("keys", "--plain")
        for alias in ("keys", "kb", "keybindings"):
            self.assertEqual(output(alias), reference)
        for text in (b"Zellij", b"Zsh", b"Neovim", b"Ctrl+a Space", b"Ctrl+a P", b"Ctrl+a S w"):
            self.assertIn(text, reference)
        self.assertNotIn(b"\x1b", reference)
        for args, overrides in [(("keys", "--plain"), {}), (("keys",), {"TERM": "dumb"})]:
            with self.terminal(*args, **overrides) as term:
                self.assertNotIn(b"\x1b", term.until(reference.rstrip().splitlines()[-1].strip()))
                self.assertEqual(term.process.wait(timeout=5), 0)
        # The CLI remains usable during a partial upgrade.
        shutil.rmtree(self.install / "lib")
        self.assertIn(b"Neovim", output("keys"))

    def test_search_details_resize_and_restore(self):
        with self.terminal(size=(12, 42)) as term:
            term.until(ENTER_SCREEN)
            home = term.until(b"Scratchpad")
            self.assertIn(b"Potions Desk", home)
            self.assertNotRegex(home, rb"\x1b\[[0-9;]*m")
            term.send(b"/*")
            term.until(b"No matching shortcuts")
            term.send(b"\x7fTELESCOPE\r")
            term.until(b"/ TELESCOPE")
            term.send(b"\r")
            term.until(b"Neovim shortcuts")
            term.until(b"Find files with Telescope")
            term.send(b"\x1b")
            term.until(b"Keyboard shortcuts")
            term.resize(6, 20)
            os.killpg(term.process.pid, signal.SIGWINCH)
            term.until(b"Resize")
            term.send(b"q")
            term.until(LEAVE_SCREEN)
            self.assertEqual(term.process.wait(timeout=5), 0)
            self.assertEqual(term.settings(), term.original)

    def test_termination_restores_terminal(self):
        with self.terminal("keys") as term:
            term.until(b"Keyboard shortcuts")
            term.process.terminate()
            term.until(LEAVE_SCREEN)
            self.assertEqual(term.process.wait(timeout=5), 143)
            self.assertEqual(term.settings(), term.original)

    def projects(self, *args):
        return subprocess.check_output(
            ["bash", self.cli, "projects", *args], cwd=self.project, env=self.env,
            stdin=subprocess.DEVNULL, timeout=5, text=True,
        )

    def test_concurrent_project_pins(self):
        other = self.home / "a project's ; $files [1]"
        other.mkdir()
        alias = self.project / "alias"
        alias.symlink_to(other, target_is_directory=True)
        # Defaults, a relative symlink and an explicit path can all race.
        requests = [(), (str(other),), ("alias",)] * 3
        with ThreadPoolExecutor(max_workers=len(requests)) as pool:
            list(pool.map(lambda args: self.projects("pin", *args), requests))
        pins = self.projects("list").splitlines()
        self.assertEqual(pins, sorted([str(self.project.resolve()), str(other.resolve())]))
        self.assertEqual(self.projects("--plain").splitlines(), pins)
        self.assertEqual(self.projects().splitlines(), pins)
        self.assertEqual(list(self.project.iterdir()), [alias])
        self.assertEqual(list(other.iterdir()), [])

        alias.unlink()
        other.rmdir()
        self.projects("unpin", str(other))
        self.assertEqual(self.projects("list").splitlines(), [str(self.project.resolve())])
        self.projects("unpin", ".")
        self.projects("unpin", ".")
        self.assertEqual(self.projects("list"), "")

        multiline_dir = self.home / "line\nbreak"
        multiline_dir.mkdir()
        for invalid in (self.home / "absent", multiline_dir):
            result = subprocess.run(["bash", self.cli, "projects", "pin", str(invalid)],
                                    env=self.env, capture_output=True, timeout=5)
            self.assertNotEqual(result.returncode, 0)
            self.assertTrue(result.stderr)
        self.assertEqual(self.projects("list"), "")

    def test_projects_switches_editor_and_git_directory(self):
        first = self.home / "personal" / "next project"
        other = self.home / "work" / "next project"
        for directory in (first, other):
            directory.mkdir(parents=True)
            self.projects("pin", str(directory))
        has_git = bool(shutil.which("git"))
        if has_git:
            subprocess.run(["git", "init", "-q"], cwd=other, env=self.env, check=True)
            (other / "only-in-next-project").touch()
        editor = self.home / "test editor"
        editor.write_text(f'#!{shutil.which("sh")}\npwd -P > "$HOME/editor-cwd"\n')
        editor.chmod(0o700)
        with self.terminal("projects", VISUAL=str(editor)) as term:
            term.until(b"Projects")
            term.until(b"~/personal/next project")
            term.until(b"~/work/next project")
            term.send(b"j\r")
            term.until(b"Workspace  ~/work/next project")
            term.send(b"\r")
            term.until(LEAVE_SCREEN)
            term.until(ENTER_SCREEN)
            self.assertEqual((self.home / "editor-cwd").read_text().strip(), str(other.resolve()))
            term.send(b"jj\r")
            term.until(b"only-in-next-project" if has_git else b"Git is unavailable")
            term.send(b"q")
            term.until(LEAVE_SCREEN)
            self.assertEqual(term.process.wait(timeout=5), 0)

    def test_unpin_replaced_project_preserves_new_target_and_foreign_links(self):
        old = self.home / "former project"
        old.mkdir()
        self.projects("pin", str(old))
        self.projects("pin", ".")
        old.rmdir()
        old.symlink_to(self.project, target_is_directory=True)
        foreign = self.install / "projects.d" / "foreign.pin"
        foreign.symlink_to(self.home, target_is_directory=True)
        for _ in range(2):
            self.projects("unpin", str(old))
            self.assertEqual(self.projects("list").splitlines(), [str(self.project.resolve())])
        self.projects("unpin", str(self.home))
        self.assertTrue(old.is_symlink())
        self.assertTrue(foreign.is_symlink())

    def test_projects_pin_and_remove_missing_folder(self):
        with self.terminal("desk") as term:
            term.until(b"Projects")
            term.send(b"\x1b[F\r")
            term.until(b"No projects pinned")
            term.send(b"p")
            term.until(b"Pinned current folder")
            self.assertEqual(self.projects("list").splitlines(), [str(self.project.resolve())])
            term.send(b"u")
            term.until(b"No projects pinned")
            term.send(b"q")
            term.until(LEAVE_SCREEN)
            self.assertEqual(term.process.wait(timeout=5), 0)
        self.assertTrue(self.project.is_dir())
        missing = self.home / "gone"
        missing.mkdir()
        self.projects("pin", str(missing))
        missing.rmdir()
        with self.terminal("projects") as term:
            term.until(b"gone")
            term.send(b"p")
            term.until(b"Pinned current folder")
            term.send(b"u")
            term.until(b"Project unpinned")
            self.assertEqual(self.projects("list").splitlines(), [str(missing.resolve())])
            term.send(b"\r")
            term.until(b"Project unavailable")
            term.send(b"u")
            term.until(b"No projects pinned")
            term.send(b"q")
            term.until(LEAVE_SCREEN)
            self.assertEqual(term.process.wait(timeout=5), 0)
        self.assertEqual(self.projects("list"), "")
        self.assertFalse(missing.exists())

    def test_editor_notes_reports_and_return(self):
        has_git = bool(shutil.which("git"))
        if has_git:
            subprocess.run(["git", "init", "-q"], cwd=self.project, env=self.env, check=True)
        (self.project / "working file").touch()
        editor = self.home / "test editor"
        editor.write_text(f"#!{shutil.which('sh')}\n" + """test -t 0 && stty -a | grep -Eq '(^|[ ;])icanon([ ;]|$)' || exit 1
if [ "$1" = . ]; then pwd > "$HOME/editor-cwd"; else echo entry >> "$1"; fi
""")
        editor.chmod(0o700)
        with self.terminal("desk", VISUAL=str(editor)) as term:
            term.until(b"Scratchpad")
            term.send(b"\r")
            term.until(LEAVE_SCREEN)
            term.until(ENTER_SCREEN)
            self.assertEqual((self.home / "editor-cwd").read_text().strip(),
                             str(self.project.resolve()))
            term.send(b"\x1b[B\r")
            term.until(LEAVE_SCREEN)
            term.until(ENTER_SCREEN)
            term.send(b"\r")
            term.until(LEAVE_SCREEN)
            term.until(ENTER_SCREEN)
            self.assertEqual((self.install / "notes.md").read_text(), "entry\nentry\n")
            term.send(b"j\r")
            term.until(b"working file" if has_git else b"Git is unavailable")
            term.send(b"\x1b")
            term.until(b"Scratchpad")
            term.send(b"jj\r")
            term.until(b"Missing essential file")
            term.send(b"q")
            term.until(LEAVE_SCREEN)
            self.assertEqual(term.process.wait(timeout=5), 0)
            self.assertEqual(term.settings(), term.original)


if __name__ == "__main__":
    unittest.main(verbosity=2)
