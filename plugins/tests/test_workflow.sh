#!/bin/bash
# Public installed CLI regression tests, isolated from user data and the network.
set -eo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TEST_ROOT=$(mktemp -d)
trap 'rm -rf "$TEST_ROOT"' EXIT
export TEST_ROOT
export POTIONS_HOME="$TEST_ROOT/Potions home"
export GIT_CONFIG_GLOBAL="$TEST_ROOT/gitconfig"
export GIT_CONFIG_NOSYSTEM=1
export GIT_ALLOW_PROTOCOL=file
mkdir -p "$POTIONS_HOME/bin" "$TEST_ROOT/projects"

# Only grep's no-match status satisfies a negative assertion.
assert_no_match() {
  local pattern="$1" status=0
  grep -Eq -- "$pattern" || status=$?
  if [ "$status" -ne 1 ]; then
    printf 'Expected no match for %s (grep exit %s)\n' "$pattern" "$status" >&2
    return 1
  fi
}

cp "$REPO_ROOT/.potions/bin/potions" "$POTIONS_HOME/bin/"
source "$REPO_ROOT/scripts/install-plugin-runtime.sh"
install_plugin_runtime "$REPO_ROOT" "$POTIONS_HOME"
cp "$REPO_ROOT/.version" "$POTIONS_HOME/.version"
CLI="$POTIONS_HOME/bin/potions"
cd "$TEST_ROOT/projects"
bash "$CLI" plugin create demo >/dev/null
[ ! -f demo/install.sh ]
[ "$(find demo -type f | wc -l | tr -d ' ')" = 3 ]
printf 'export TEST_PLUGIN_ACTIVE=1\n' >> demo/config/init.zsh
bash "$CLI" plugin validate ./demo >/dev/null
bash "$CLI" plugin install ./demo >/dev/null
bash "$CLI" plugin install ./demo >/dev/null
bash "$CLI" plugin list | grep 'active' >/dev/null
bash "$CLI" plugin deactivate demo >/dev/null
grep -q '^demo:inactive:' "$POTIONS_HOME/plugins/.state"
bash "$CLI" plugin activate demo >/dev/null
if command -v zsh >/dev/null; then
  mkdir -p "$TEST_ROOT/zsh"
  ZDOTDIR="$TEST_ROOT/zsh" POTIONS_TEST_ZSHRC="$REPO_ROOT/.potions/.zshrc" zsh -f -c 'source "$POTIONS_TEST_ZSHRC"; [[ "$TEST_PLUGIN_ACTIVE" = 1 ]]'

fi
bash "$CLI" plugin uninstall demo >/dev/null
[ -f "$TEST_ROOT/projects/demo/config/init.zsh" ]
[ ! -e "$POTIONS_HOME/plugins/demo" ]
assert_no_match '^demo[|]' < "$POTIONS_HOME/Potionfile.lock"
assert_no_match '^demo:' < "$POTIONS_HOME/plugins/.state"
if bash "$CLI" plugin create ../escape >/dev/null 2>&1; then exit 1; fi
if bash "$CLI" plugin install https://example.com/bad/repo --trust >/dev/null 2>&1; then exit 1; fi
# Redirect a GitHub URL to a real local Git repository without network access.
git -C demo init -q
git -C demo add .
git -C demo -c user.name=Fixture -c user.email=fixture@example.test commit -qm initial
git -C demo tag v0.1.0
first_commit=$(git -C demo rev-parse HEAD)
git config --file "$GIT_CONFIG_GLOBAL" url."file://$TEST_ROOT/projects/".insteadOf https://github.com/fixture/
# Git appends .git to URLs, so expose the fixture under that name.
ln -s "$TEST_ROOT/projects/demo" "$TEST_ROOT/projects/demo.git"
if bash "$CLI" plugin install fixture/demo@v0.1.0 >/dev/null 2>&1; then exit 1; fi
[ ! -e "$POTIONS_HOME/plugins/demo" ]
bash "$CLI" plugin install fixture/demo@v0.1.0 --trust >/dev/null 2>&1
grep -Fq "demo|0.1.0|$first_commit|github:fixture/demo, tag: v0.1.0" "$POTIONS_HOME/Potionfile.lock"
bash "$CLI" plugin deactivate demo >/dev/null
cp "$POTIONS_HOME/Potionfile.lock" "$TEST_ROOT/old.lock"
cp "$POTIONS_HOME/plugins/.state" "$TEST_ROOT/old.state"
cp "$POTIONS_HOME/plugins/.init.zsh" "$TEST_ROOT/old.init"
printf '#!/bin/bash\nexit 17\n' > demo/install.sh
chmod +x demo/install.sh
git -C demo add install.sh
git -C demo -c user.name=Fixture -c user.email=fixture@example.test commit -qm failing
git -C demo tag v0.2.0
if bash "$CLI" plugin install fixture/demo@v0.2.0 --trust --force >/dev/null 2>&1; then exit 1; fi
[ "$(git -C "$POTIONS_HOME/plugins/demo" rev-parse HEAD)" = "$first_commit" ]
cmp "$TEST_ROOT/old.lock" "$POTIONS_HOME/Potionfile.lock"
cmp "$TEST_ROOT/old.state" "$POTIONS_HOME/plugins/.state"
cmp "$TEST_ROOT/old.init" "$POTIONS_HOME/plugins/.init.zsh"
# Updating the tagged installation preserves both its tag and disabled state.
bash "$CLI" plugin update demo --trust >/dev/null 2>&1
grep -q '^demo:inactive:' "$POTIONS_HOME/plugins/.state"
[ "$(git -C "$POTIONS_HOME/plugins/demo" rev-parse HEAD)" = "$first_commit" ]
bash "$CLI" plugin status | grep 'Lockfile verification passed' >/dev/null
# Potionfile failures propagate and malicious names stay data.
printf "plugin 'fixture/demo', tag: 'missing'\n" > "$POTIONS_HOME/Potionfile"
if bash "$CLI" plugin install >/dev/null 2>&1; then exit 1; fi
bash "$CLI" plugin uninstall demo >/dev/null
bash "$CLI" plugin create yaml-demo --potion >/dev/null
bash "$CLI" plugin validate ./yaml-demo >/dev/null
bash "$CLI" plugin install ./yaml-demo >/dev/null
bash "$CLI" plugin uninstall yaml-demo >/dev/null
# Live mutations refuse competitors, and stale owners can be recovered.
mkdir "$POTIONS_HOME/plugins/.operation-lock"
printf '%s\n' "$$" > "$POTIONS_HOME/plugins/.operation-lock/pid"
if bash "$CLI" plugin install ./yaml-demo >/dev/null 2>&1; then exit 1; fi
[ ! -e "$POTIONS_HOME/plugins/yaml-demo" ]
printf '99999999\n' > "$POTIONS_HOME/plugins/.operation-lock/pid"
bash "$CLI" plugin install ./yaml-demo >/dev/null
[ ! -d "$POTIONS_HOME/plugins/.operation-lock" ]
bash "$CLI" plugin uninstall yaml-demo >/dev/null
# Completed entries remain loadable when another Potionfile entry fails.
printf "  local_plugin '%s'\nplugin 'fixture/demo', tag: 'missing'\n" "$TEST_ROOT/projects/yaml-demo" > "$POTIONS_HOME/Potionfile"
if bash "$CLI" plugin install >/dev/null 2>&1; then exit 1; fi
grep -q '^yaml-demo:active:' "$POTIONS_HOME/plugins/.state"
grep -q "_potions_source_plugin 'yaml-demo'" "$POTIONS_HOME/plugins/.init.zsh"
bash "$CLI" plugin uninstall yaml-demo >/dev/null
# Serve reviewed Shelf data locally, including current catalog refreshes.
mkdir -p "$TEST_ROOT/bin" "$POTIONS_HOME/.registry/manifests"
printf '#!%s\n' "$BASH" > "$TEST_ROOT/bin/curl"
cat >> "$TEST_ROOT/bin/curl" <<'EOF'
set -eu
[ "${TEST_REGISTRY_OFFLINE:-0}" != 1 ] || exit 7
url=""
output=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    -o) output="$2"; shift 2 ;;
    http*) url="$1"; shift ;;
    *) shift ;;
  esac
done
case "$url" in
  https://raw.githubusercontent.com/Rynaro/potions-shelf/main/index.json)
    cp "$TEST_ROOT/remote-index.json" "$output" ;;
  https://raw.githubusercontent.com/Rynaro/potions-shelf/main/plugins/demo.potion)
    cp "$TEST_ROOT/remote-demo.potion" "$output" ;;
  *) exit 22 ;;
esac
EOF
chmod +x "$TEST_ROOT/bin/curl"
export PATH="$TEST_ROOT/bin:$PATH"
cat > "$TEST_ROOT/remote-index.json" <<EOF
{
  "version": "1.0.0",
  "plugins": [
    {"metadata": {"name": "other", "reviewed_commit": "ignored"}, "name": "demo", "description": "Catalog entry with [literal] text", "repository": "https://github.com/fixture/demo@v0.1.0", "version": "0.1.0", "reviewed_commit": "$first_commit"}
  ]
}
EOF
cat > "$TEST_ROOT/remote-demo.potion" <<EOF
name: demo
version: "0.1.0"
description: "Catalog entry with [literal] text"
author: "Fixture"
repository: "https://github.com/fixture/demo@v0.1.0"
reviewed_commit: $first_commit
checksum: "sha256:0000000000000000000000000000000000000000000000000000000000000000"
EOF
cp "$TEST_ROOT/remote-index.json" "$POTIONS_HOME/.registry/index.json"
cp "$TEST_ROOT/remote-demo.potion" "$POTIONS_HOME/.registry/manifests/demo.potion"
date +%s > "$POTIONS_HOME/.registry/.timestamp"
search_output=$(bash "$CLI" plugin search '[' 2>&1)
printf '%s\n' "$search_output" | grep -Fx '  demo' >/dev/null
assert_no_match 'Directory .* already exists' <<< "$search_output"
no_match_output=$(bash "$CLI" plugin search '.*' 2>&1)
printf '%s\n' "$no_match_output" | grep -F 'No plugins found matching: .*' >/dev/null
info_output=$(bash "$CLI" plugin info demo 2>&1)
printf '%s\n' "$info_output" | grep -F 'Catalog: Listed in Potions Shelf' >/dev/null
assert_no_match 'Verified by Potions Quality Assurance|Safe to install|Checksum URL:' <<< "$info_output"
if bash "$CLI" plugin install demo </dev/null >/dev/null 2>&1; then exit 1; fi
[ ! -e "$POTIONS_HOME/plugins/demo" ]
# Old locks cannot distinguish direct installs from pre-pin registry installs.
# Adopting the registry explicitly preserves the previously disabled state.
bash "$CLI" plugin install fixture/demo@v0.1.0 --trust >/dev/null 2>&1
bash "$CLI" plugin deactivate demo >/dev/null
bash "$CLI" plugin install demo --force --trust >/dev/null 2>&1
grep -Fq "demo|0.1.0|$first_commit|registry:demo" "$POTIONS_HOME/Potionfile.lock"
grep -q '^demo:inactive:' "$POTIONS_HOME/plugins/.state"
cp "$POTIONS_HOME/Potionfile.lock" "$TEST_ROOT/registry.lock"
cp "$POTIONS_HOME/plugins/.state" "$TEST_ROOT/registry.state"
cp "$POTIONS_HOME/plugins/.init.zsh" "$TEST_ROOT/registry.init"
# A moved tag is rejected before its optional hook, regardless of bypass flags.
printf '#!/bin/bash\nprintf ran > "$TEST_ROOT/hook-ran"\n' > demo/install.sh
git -C demo add install.sh
git -C demo -c user.name=Fixture -c user.email=fixture@example.test commit -qm changed
git -C demo tag -f v0.1.0 >/dev/null
changed_commit=$(git -C demo rev-parse HEAD)
if bash "$CLI" plugin update demo --trust --skip-security >/dev/null 2>&1; then exit 1; fi
[ ! -e "$TEST_ROOT/hook-ran" ]
[ "$(git -C "$POTIONS_HOME/plugins/demo" rev-parse HEAD)" = "$first_commit" ]
cmp "$TEST_ROOT/registry.lock" "$POTIONS_HOME/Potionfile.lock"
cmp "$TEST_ROOT/registry.state" "$POTIONS_HOME/plugins/.state"
cmp "$TEST_ROOT/registry.init" "$POTIONS_HOME/plugins/.init.zsh"
# Missing or malformed reviewed revisions cannot fall back to direct installs.
cp "$TEST_ROOT/remote-demo.potion" "$TEST_ROOT/reviewed.potion"
sed '/^reviewed_commit:/d' "$TEST_ROOT/reviewed.potion" > "$TEST_ROOT/remote-demo.potion"
if bash "$CLI" plugin install demo --force --trust --skip-security >/dev/null 2>&1; then exit 1; fi
printf 'reviewed_commit: invalid\n' >> "$TEST_ROOT/remote-demo.potion"
if bash "$CLI" plugin update demo --trust --skip-security >/dev/null 2>&1; then exit 1; fi
[ ! -e "$TEST_ROOT/hook-ran" ]
# A raw manifest merged ahead of a successful index publication cannot advance
# the revision or source that the published catalog reviewed.
sed "s/$first_commit/$changed_commit/" "$TEST_ROOT/reviewed.potion" > "$TEST_ROOT/remote-demo.potion"
if bash "$CLI" plugin update demo --trust --skip-security >/dev/null 2>&1; then exit 1; fi
[ ! -e "$TEST_ROOT/hook-ran" ]
cmp "$TEST_ROOT/registry.lock" "$POTIONS_HOME/Potionfile.lock"
sed 's|fixture/demo@|fixture/other@|' "$TEST_ROOT/reviewed.potion" > "$TEST_ROOT/remote-demo.potion"
if bash "$CLI" plugin update demo --trust --skip-security >/dev/null 2>&1; then exit 1; fi
[ ! -e "$TEST_ROOT/hook-ran" ]
# An approved new revision can update while retaining registry provenance/state.
sed "s/$first_commit/$changed_commit/" "$TEST_ROOT/reviewed.potion" > "$TEST_ROOT/remote-demo.potion"
sed "s/$first_commit/$changed_commit/" "$TEST_ROOT/remote-index.json" > "$TEST_ROOT/updated-index.json"
mv "$TEST_ROOT/updated-index.json" "$TEST_ROOT/remote-index.json"
bash "$CLI" plugin update demo --trust --skip-security >/dev/null 2>&1
[ "$(cat "$TEST_ROOT/hook-ran")" = ran ]
grep -Fq "demo|0.1.0|$changed_commit|registry:demo" "$POTIONS_HOME/Potionfile.lock"
grep -q '^demo:inactive:' "$POTIONS_HOME/plugins/.state"
# A current catalog is mandatory even when a valid cached entry exists.
cp "$POTIONS_HOME/Potionfile.lock" "$TEST_ROOT/registry.lock"
if TEST_REGISTRY_OFFLINE=1 bash "$CLI" plugin update demo --trust >/dev/null 2>&1; then exit 1; fi
cmp "$TEST_ROOT/registry.lock" "$POTIONS_HOME/Potionfile.lock"
cat > "$TEST_ROOT/remote-index.json" <<'EOF'
{"version":"1.0.0","plugins":[],"categories":{}}
EOF
if bash "$CLI" plugin update demo --trust >/dev/null 2>&1; then exit 1; fi
cmp "$TEST_ROOT/registry.lock" "$POTIONS_HOME/Potionfile.lock"
bash "$CLI" plugin uninstall demo >/dev/null
[ ! -e "$POTIONS_HOME/.registry/manifests/demo.potion" ]
if bash "$CLI" plugin info demo >/dev/null 2>&1; then exit 1; fi
if bash "$CLI" plugin install demo </dev/null >/dev/null 2>&1; then exit 1; fi
printf 'Plugin workflow tests passed.\n'
