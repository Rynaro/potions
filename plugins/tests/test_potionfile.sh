#!/bin/bash
# Exercise declared installs through the deployed CLI with isolated local sources.
set -eo pipefail
repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
test_root=$(mktemp -d)
test_root=$(cd "$test_root" && pwd -P)
trap 'rm -rf "$test_root"' EXIT
export POTIONS_HOME="$test_root/Potions home"
export GIT_CONFIG_GLOBAL="$test_root/gitconfig" GIT_CONFIG_NOSYSTEM=1 GIT_ALLOW_PROTOCOL=file
mkdir -p "$POTIONS_HOME/bin" "$test_root/projects" "$test_root/caller"
cp "$repo_root/.potions/bin/potions" "$POTIONS_HOME/bin/"
source "$repo_root/scripts/install-plugin-runtime.sh"
install_plugin_runtime "$repo_root" "$POTIONS_HOME" > "$test_root/deploy.log" 2>&1
cp "$repo_root/.version" "$POTIONS_HOME/.version"
cli="$POTIONS_HOME/bin/potions"

make_plugin() {
  local name="$1" parent="$2"
  (cd "$parent" && bash "$cli" plugin create "$name") > /dev/null
}

# The same relative spelling must resolve from the declarations' directory.
make_plugin beside "$POTIONS_HOME"
printf "local_plugin './beside'\n" > "$POTIONS_HOME/Potionfile"
cd "$test_root/caller"
bash "$cli" plugin install --trust > "$test_root/relative.log"
[ "$(readlink "$POTIONS_HOME/plugins/beside")" = "$POTIONS_HOME/beside" ]

# Keep older caller-relative declarations working with an explicit migration tip.
make_plugin legacy "$test_root/caller"
printf "local_plugin './legacy'\n" > "$POTIONS_HOME/Potionfile"
bash "$cli" plugin install > "$test_root/legacy.log"
[ "$(readlink "$POTIONS_HOME/plugins/legacy")" = "$test_root/caller/legacy" ]
grep -Fq 'Using caller-relative local plugin path' "$test_root/legacy.log"

# Local Git remotes exercise real clone/revision and trust behavior offline.
for name in remote-one remote-two; do
  make_plugin "$name" "$test_root/projects"
  git -C "$test_root/projects/$name" init -q
  git -C "$test_root/projects/$name" add .
  git -C "$test_root/projects/$name" -c user.name=Fixture -c user.email=fixture@localhost \
    -c commit.gpgsign=false -c core.hooksPath=/dev/null commit -qm initial
  git -C "$test_root/projects/$name" tag v0.1.0
  ln -s "$test_root/projects/$name" "$test_root/projects/$name.git"
done
git config --file "$GIT_CONFIG_GLOBAL" url."file://$test_root/projects/".insteadOf https://github.com/fixture/

printf "plugin 'fixture/remote-one', tag: 'v0.1.0'\n" > "$POTIONS_HOME/Potionfile"
if bash "$cli" plugin install > "$test_root/without-trust.log" 2>&1; then
  printf '%s\n' 'Batch install approved a remote source without consent.' >&2
  exit 1
fi
grep -Fq 'then install with --trust' "$test_root/without-trust.log"
[ ! -e "$POTIONS_HOME/plugins/remote-one" ]

# A failed declaration reports failure while later reviewed entries still load.
printf "plugin 'fixture/remote-one', tag: 'missing'\nplugin 'fixture/remote-two', tag: 'v0.1.0'\n" > "$POTIONS_HOME/Potionfile"
if bash "$cli" plugin install --trust > "$test_root/partial.log" 2>&1; then exit 1; fi
grep -Eq '^remote-two:active:' "$POTIONS_HOME/plugins/.state"
grep -Fq "_potions_source_plugin 'remote-two'" "$POTIONS_HOME/plugins/.init.zsh"
bash "$cli" plugin uninstall remote-two > /dev/null

# Terminal approvals must come from stdin, independently of declarations.
if command -v python3 > /dev/null 2>&1; then
  printf "plugin 'fixture/remote-one', tag: 'v0.1.0'\nplugin 'fixture/remote-two', tag: 'v0.1.0'\n" > "$POTIONS_HOME/Potionfile"
  python3 - "$cli" <<'PY'
import errno
import os
import pty
import select
import subprocess
import sys
import time

master, slave = pty.openpty()
process = subprocess.Popen(["bash", sys.argv[1], "plugin", "install"], stdin=slave, stdout=slave, stderr=slave)
os.close(slave)
output = bytearray()
approvals = 0
deadline = time.monotonic() + 30
try:
    while process.poll() is None:
        if time.monotonic() > deadline:
            raise AssertionError("Timed out waiting for batch trust prompts")
        if not select.select([master], [], [], 0.2)[0]:
            continue
        try:
            chunk = os.read(master, 65536)
        except OSError as error:
            if error.errno == errno.EIO:
                break
            raise
        output.extend(chunk)
        prompts = output.count(b"Trust this revision? [y/N]")
        while approvals < prompts:
            os.write(master, b"y\n")
            approvals += 1
    assert process.wait(timeout=5) == 0, output.decode(errors="replace")
    assert approvals == 2, output.decode(errors="replace")
finally:
    if process.poll() is None:
        process.kill()
        process.wait()
    os.close(master)
PY
  grep -Eq '^remote-one:active:' "$POTIONS_HOME/plugins/.state"
  grep -Eq '^remote-two:active:' "$POTIONS_HOME/plugins/.state"
else
  printf '%s\n' 'Interactive approval checks require Python 3.'
fi

# Unknown options and extra sources fail before changing an installed package.
if bash "$cli" plugin install --unknown > /dev/null 2>&1; then exit 1; fi
if bash "$cli" plugin install ./beside ./legacy > /dev/null 2>&1; then exit 1; fi
printf '%s\n' 'Potionfile paths, batch options, partial failure, and trust approval passed.'
