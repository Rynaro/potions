#!/bin/bash
# Exercise syntax validation and per-plugin integrity through the shipped CLI.
# The parser-policy subshell deliberately isolates sourced environment defaults.
# shellcheck disable=SC2030,SC2031
set -eo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
test_root=$(mktemp -d)
trap 'rm -rf "$test_root"' EXIT
export POTIONS_HOME="$test_root/Potions home"
export GIT_CONFIG_GLOBAL="$test_root/gitconfig" GIT_CONFIG_NOSYSTEM=1
mkdir -p "$POTIONS_HOME/bin" "$test_root/plugin/config"
cp "$repo_root/.potions/bin/potions" "$POTIONS_HOME/bin/"
source "$repo_root/scripts/install-plugin-runtime.sh"
install_plugin_runtime "$repo_root" "$POTIONS_HOME" > "$test_root/deploy.log" 2>&1
cli="$POTIONS_HOME/bin/potions"

cat > "$test_root/plugin/plugin.potions.json" <<'JSON'
{"name":"verification-demo","version":"1.0.0","description":"Verification fixture","author":"Potions tests","potions_min_version":"2.6.0"}
JSON
printf '%s\n' 'if true; then' > "$test_root/plugin/config/init.zsh"
printf 'printf done > "%s"\n' "$test_root/hook-ran" > "$test_root/plugin/install.sh"
chmod +x "$test_root/plugin/install.sh"

if command -v zsh >/dev/null 2>&1; then
  if bash "$cli" plugin validate "$test_root/plugin" > "$test_root/invalid.log" 2>&1; then exit 1; fi
  if bash "$cli" plugin install "$test_root/plugin" > "$test_root/install-invalid.log" 2>&1; then exit 1; fi
  [ ! -e "$test_root/hook-ran" ]
  [ ! -e "$POTIONS_HOME/plugins/verification-demo" ]
  if bash "$cli" plugin verify "$test_root/plugin" > "$test_root/audit-invalid.log" 2>&1; then exit 1; fi
  grep -Fq 'Zsh syntax error' "$test_root/invalid.log"
  # This short for loop is valid Zsh and is rejected by Bash's parser.
  cat > "$test_root/plugin/config/init.zsh" <<'ZSH'
for value (one two) print -r -- "$value"
ZSH
  bash "$cli" plugin validate "$test_root/plugin" > "$test_root/valid.log" 2>&1
  printf '%s\n' 'if true; then' > "$test_root/plugin/config/extra.sh"
  if bash "$cli" plugin validate "$test_root/plugin" > "$test_root/invalid-sh.log" 2>&1; then exit 1; fi
  rm "$test_root/plugin/config/extra.sh"
else
  if bash "$cli" plugin validate "$test_root/plugin" > "$test_root/no-zsh.log" 2>&1; then exit 1; fi
  grep -Fq 'Zsh is required' "$test_root/no-zsh.log"
fi

# Check both parser policies even on machines that have Zsh installed.
(
  source "$repo_root/packages/accessories.sh"
  source "$repo_root/plugins/core/manifest.sh"
  command_exists() { [ "$1" != zsh ]; }
  validate_plugin "$test_root/plugin" --defer-zsh > "$test_root/deferred.log" 2>&1
  if validate_plugin "$test_root/plugin" --require-zsh > "$test_root/required.log" 2>&1; then exit 1; fi
)
grep -Fq 'shell configuration syntax awaits Zsh' "$test_root/deferred.log"
grep -Fq 'Zsh is required' "$test_root/required.log"

cat > "$test_root/without-zsh.bash" <<'BASH'
command() {
  if [ "${1:-}" = -v ] && [ "${2:-}" = zsh ]; then return 1; fi
  builtin command "$@"
}
BASH
if BASH_ENV="$test_root/without-zsh.bash" bash "$cli" plugin install "$test_root/plugin" > "$test_root/install-no-zsh.log" 2>&1; then exit 1; fi
grep -Fq 'Zsh is required' "$test_root/install-no-zsh.log"
[ ! -e "$test_root/hook-ran" ]
BASH_ENV="$test_root/without-zsh.bash" POTIONS_HOME="$test_root/bundle-without-zsh" \
  install_plugin_runtime "$repo_root" "$test_root/bundle-without-zsh" > "$test_root/bundle-no-zsh.log" 2>&1
grep -Fq 'Shell configuration syntax checks deferred' "$test_root/bundle-no-zsh.log"

# Verify a regular remote snapshot using benign local Git data and no network.
rm "$test_root/plugin/install.sh" "$test_root/plugin/config/init.zsh"
git -c init.defaultBranch=main init -q "$test_root/plugin"
printf '%s\n' 'config/optional.zsh' 'cache/' > "$test_root/plugin/.gitignore"
git -C "$test_root/plugin" add plugin.potions.json .gitignore
git -C "$test_root/plugin" -c user.name=Fixture -c user.email=fixture@example.test \
  -c commit.gpgsign=false -c core.hooksPath=/dev/null commit -qm fixture
commit=$(git -C "$test_root/plugin" rev-parse HEAD)
cp -R "$test_root/plugin" "$POTIONS_HOME/plugins/verification-demo"
printf 'verification-demo|1.0.0|%s|github:fixture/verification-demo\n' "$commit" >> "$POTIONS_HOME/Potionfile.lock"
printf '%s\n' 'verification-demo:active:1.0.0' >> "$POTIONS_HOME/plugins/.state"
mkdir "$test_root/verification-demo"
printf '%s\n' 'invalid manifest' > "$test_root/verification-demo/plugin.potions.json"
cd "$test_root"
bash "$cli" plugin verify verification-demo > "$test_root/verify-clean.log" 2>&1
if bash "$cli" plugin verify ./verification-demo > "$test_root/verify-path.log" 2>&1; then exit 1; fi
printf '%s\n' 'ordinary local note' > "$POTIONS_HOME/plugins/verification-demo/notes.txt"
if bash "$cli" plugin verify verification-demo > "$test_root/verify-changed.log" 2>&1; then exit 1; fi
grep -Fq 'differs from recorded Git revision' "$test_root/verify-changed.log"
bash "$cli" plugin verify "$test_root/plugin" > "$test_root/verify-other.log" 2>&1
if bash "$cli" plugin status > "$test_root/status-changed.log" 2>&1; then exit 1; fi
rm "$POTIONS_HOME/plugins/verification-demo/notes.txt"
bash "$cli" plugin status > "$test_root/status-clean.log" 2>&1
mkdir "$POTIONS_HOME/plugins/verification-demo/cache"
printf '%s\n' 'ordinary ignored cache' > "$POTIONS_HOME/plugins/verification-demo/cache/build.txt"
bash "$cli" plugin status > "$test_root/status-cache.log" 2>&1
printf '%s\n' '# additional shell configuration' > "$POTIONS_HOME/plugins/verification-demo/config/optional.zsh"
if bash "$cli" plugin status > "$test_root/status-ignored-config.log" 2>&1; then exit 1; fi
grep -Fq 'differs from recorded Git revision' "$test_root/status-ignored-config.log"
rm "$POTIONS_HOME/plugins/verification-demo/config/optional.zsh"

cp "$POTIONS_HOME/Potionfile.lock" "$test_root/clean.lock"
replace_fixture_record() {
  awk -F'|' '$1 != "verification-demo"' "$test_root/clean.lock" > "$POTIONS_HOME/Potionfile.lock"
  printf 'verification-demo|1.0.0|%s|%s\n' "$1" "$2" >> "$POTIONS_HOME/Potionfile.lock"
}
replace_fixture_record none github:fixture/verification-demo
if bash "$cli" plugin verify verification-demo > "$test_root/no-commit.log" 2>&1; then exit 1; fi
grep -Fq 'Recorded Git revision is unavailable' "$test_root/no-commit.log"
replace_fixture_record none unknown
if bash "$cli" plugin verify verification-demo > "$test_root/unknown-source.log" 2>&1; then exit 1; fi
grep -Fq 'Plugin provenance is unavailable' "$test_root/unknown-source.log"
cp "$test_root/clean.lock" "$POTIONS_HOME/Potionfile.lock"
mv "$POTIONS_HOME/plugins/verification-demo" "$test_root/remote-snapshot"
if bash "$cli" plugin verify verification-demo > "$test_root/missing-installed.log" 2>&1; then exit 1; fi
grep -Fq 'Plugin not found' "$test_root/missing-installed.log"

ln -s "$test_root/plugin" "$POTIONS_HOME/plugins/verification-demo"
replace_fixture_record none "local:$test_root/plugin"
bash "$cli" plugin verify verification-demo > "$test_root/local-clean.log" 2>&1
mkdir "$test_root/local-copy"
cp -R "$test_root/plugin/." "$test_root/local-copy/"
rm "$POTIONS_HOME/plugins/verification-demo"
ln -s "$test_root/local-copy" "$POTIONS_HOME/plugins/verification-demo"
if bash "$cli" plugin verify verification-demo > "$test_root/local-moved.log" 2>&1; then exit 1; fi
grep -Fq 'Local plugin path differs' "$test_root/local-moved.log"
rm "$POTIONS_HOME/plugins/verification-demo"
mv "$test_root/remote-snapshot" "$POTIONS_HOME/plugins/verification-demo"
cp "$test_root/clean.lock" "$POTIONS_HOME/Potionfile.lock"
awk -F'|' '$1 != "verification-demo"' "$test_root/clean.lock" > "$POTIONS_HOME/Potionfile.lock"
if bash "$cli" plugin status > "$test_root/missing-record.log" 2>&1; then exit 1; fi
grep -Fq 'Installed plugin has no lockfile record' "$test_root/missing-record.log"
cp "$test_root/clean.lock" "$POTIONS_HOME/Potionfile.lock"
: > "$POTIONS_HOME/Potionfile.lock"
if bash "$cli" plugin status > "$test_root/empty-lock.log" 2>&1; then exit 1; fi
grep -Fq 'Installed plugin has no lockfile record' "$test_root/empty-lock.log"
cp "$test_root/clean.lock" "$POTIONS_HOME/Potionfile.lock"

bundle_path=$(readlink "$POTIONS_HOME/plugins/word-navigation")
mkdir "$test_root/bundle-copy"
cp -R "$bundle_path/." "$test_root/bundle-copy/"
rm "$POTIONS_HOME/plugins/word-navigation"
ln -s "$test_root/bundle-copy" "$POTIONS_HOME/plugins/word-navigation"
if bash "$cli" plugin status > "$test_root/bundle-moved.log" 2>&1; then exit 1; fi
grep -Fq 'Bundled plugin path differs' "$test_root/bundle-moved.log"
rm "$POTIONS_HOME/plugins/word-navigation"
ln -s "$bundle_path" "$POTIONS_HOME/plugins/word-navigation"
bash "$cli" plugin status > "$test_root/status-restored.log" 2>&1

POTIONS_HOME="$test_root/empty" bash "$repo_root/plugins.sh" status > "$test_root/status-empty.log" 2>&1
printf '%s\n' 'Plugin syntax validation, independent integrity verification, and status results passed.'
