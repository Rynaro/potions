#!/bin/bash
# Exercise the default plugin through the deployed CLI without network access.
set -eo pipefail

# These fixtures contain text. Appending a sentinel preserves trailing newlines
# during command substitution and avoids requiring the diffutils package.
assert_same_text() {
  local expected actual
  expected=$(cat -- "$1" && printf '\001') || return 1
  actual=$(cat -- "$2" && printf '\001') || return 1
  if [ "$expected" != "$actual" ]; then
    printf 'Text differs between %s and %s\n' "$1" "$2" >&2
    return 1
  fi
}

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
test_root=$(mktemp -d)
test_root=$(cd "$test_root" && pwd -P)
trap 'rm -rf "$test_root"' EXIT
export POTIONS_HOME="$test_root/Potions home"
export GIT_CONFIG_GLOBAL="$test_root/gitconfig"
export GIT_CONFIG_NOSYSTEM=1
export GIT_ALLOW_PROTOCOL=file
mkdir -p "$test_root/home" "$POTIONS_HOME/bin" "$POTIONS_HOME/config"
cp "$repo_root/.potions/bin/potions" "$POTIONS_HOME/bin/"
# shellcheck source=scripts/install-plugin-runtime.sh
source "$repo_root/scripts/install-plugin-runtime.sh"
cli="$POTIONS_HOME/bin/potions"
installed="$POTIONS_HOME/plugins/word-navigation"

deploy_runtime() {
  install_plugin_runtime "$repo_root" "$POTIONS_HOME" > "$test_root/deploy.log" 2>&1 || {
    cat "$test_root/deploy.log" >&2
    return 1
  }
}

deploy_runtime
[ -L "$installed" ]
[ -f "$installed/plugin.potions.json" ]
grep -Eq '^word-navigation:active:' "$POTIONS_HOME/plugins/.state"
bash "$cli" plugin validate "$installed" > /dev/null
bash "$cli" plugin list | grep -E 'word-navigation.*\(bundled\)' > /dev/null
bash "$cli" plugin info word-navigation | grep -Fx 'Type: Bundled plugin' > /dev/null
bash "$cli" plugin info word-navigation | grep -Fx 'Updates: Managed by Potions releases' > /dev/null
grep -Fxq 'word-navigation|1.0.0|none|bundled:word-navigation' "$POTIONS_HOME/Potionfile.lock"
bash "$cli" plugin status | grep -F 'Lockfile verification passed' > /dev/null
cp "$POTIONS_HOME/plugins/.state" "$test_root/initial.state"
cp "$POTIONS_HOME/Potionfile.lock" "$test_root/initial.lock"
deploy_runtime
assert_same_text "$test_root/initial.state" "$POTIONS_HOME/plugins/.state"
assert_same_text "$test_root/initial.lock" "$POTIONS_HOME/Potionfile.lock"
bash "$cli" plugin update --all > /dev/null

# Start all relevant bindings from known sentinels. Platform configuration
# runs after ordinary plugins and previously ran before the built-in bindings.
cat > "$POTIONS_HOME/config/local.zsh" <<'ZSH'
if [[ "$TEST_NAV_KEYMAP" = viins ]]; then
  bindkey -v
else
  bindkey -e
fi
for sequence in '^[[1;5C' '^[[1;5D' '^[[5C' '^[[5D' '^[f' '^[b'; do
  bindkey "$sequence" undefined-key
done
ZSH
for platform in macos linux wsl termux; do
  cat > "$POTIONS_HOME/config/$platform.zsh" <<'ZSH'
export TEST_PLATFORM_CONFIGURATION_LOADED=1
bindkey '^[[1;5C' end-of-line
ZSH
done
cat > "$test_root/check-startup.zsh" <<'ZSH'
# Stub the optional host integration so this exercises only disposable files.
brew() { [[ "$1" = --prefix ]] && print -r -- "$POTIONS_HOME/unused-brew-prefix"; return 0 }
source "$TEST_NAV_ZSHRC"
[[ "$TEST_PLATFORM_CONFIGURATION_LOADED" = 1 ]] || exit 1
[[ "$HISTFILE" = "$POTIONS_HOME/.zsh_history" ]] || exit 1
[[ "$HISTSIZE" = 10000 && "$SAVEHIST" = 10000 ]] || exit 1
[[ -o SHARE_HISTORY && -o HIST_IGNORE_ALL_DUPS ]] || exit 1

expect_binding() {
  local sequence="$1" widget="$2" actual
  actual=$(bindkey "$sequence") || return 1
  if [[ "$actual" != *" $widget" ]]; then
    print -ru2 -- "$TERM_PROGRAM/$TEST_NAV_KEYMAP expected $sequence $widget, got $actual"
    return 1
  fi
}

if [[ "$TEST_NAV_ACTIVE" = 1 ]]; then
  expect_binding '^[[1;5C' forward-word || exit 1
  expect_binding '^[[1;5D' backward-word || exit 1
  expect_binding '^[[5C' forward-word || exit 1
  expect_binding '^[[5D' backward-word || exit 1
  case "$TERM_PROGRAM" in
    Apple_Terminal|fixture-unknown)
      expect_binding '^[f' forward-word || exit 1
      expect_binding '^[b' backward-word || exit 1
      ;;
    *)
      expect_binding '^[f' undefined-key || exit 1
      expect_binding '^[b' undefined-key || exit 1
      ;;
  esac
else
  expect_binding '^[[1;5C' end-of-line || exit 1
  for sequence in '^[[1;5D' '^[[5C' '^[[5D' '^[f' '^[b'; do
    expect_binding "$sequence" undefined-key || exit 1
  done
fi
ZSH

check_startup() {
  local active="$1" terminal keymap
  if ! command -v zsh > /dev/null 2>&1; then
    return 0
  fi
  for terminal in iTerm.app Apple_Terminal vscode cursor fixture-unknown; do
    for keymap in emacs viins; do
      env HOME="$test_root/home" ZDOTDIR="$test_root/home" EDITOR=emacs VISUAL=emacs \
        TERM_PROGRAM="$terminal" ZELLIJ=1 POTIONS_MIGRATION_CHECKED=1 \
        TEST_NAV_ACTIVE="$active" TEST_NAV_KEYMAP="$keymap" \
        TEST_NAV_ZSHRC="$repo_root/.potions/.zshrc" \
        zsh -f -i "$test_root/check-startup.zsh"
    done
  done
}

check_startup 1
bash "$cli" plugin deactivate word-navigation > /dev/null
bash "$cli" plugin update --all > /dev/null
# A later Potions release replaces the managed bundle before bootstrap runs.
# Change only this disposable runtime to simulate its next manifest revision.
managed_manifest="$POTIONS_HOME/lib/plugin-manager/plugins/bundled/word-navigation/plugin.potions.json"
sed 's/"version": "1.0.0"/"version": "1.1.0"/' "$managed_manifest" > "$test_root/next-manifest.json"
mv "$test_root/next-manifest.json" "$managed_manifest"
bash "$POTIONS_HOME/lib/plugin-manager/plugins.sh" bootstrap-defaults > /dev/null
grep -Fxq 'word-navigation:inactive:1.1.0' "$POTIONS_HOME/plugins/.state"
grep -Fxq 'word-navigation|1.1.0|none|bundled:word-navigation' "$POTIONS_HOME/Potionfile.lock"
bash "$cli" plugin status | grep -F 'Lockfile verification passed' > /dev/null
check_startup 0
deploy_runtime
grep -Eq '^word-navigation:inactive:' "$POTIONS_HOME/plugins/.state"
check_startup 0
bash "$cli" plugin activate word-navigation > /dev/null
check_startup 1
bash "$cli" plugin uninstall word-navigation > /dev/null
deploy_runtime
[ ! -e "$installed" ]
[ ! -L "$installed" ]
check_startup 0
bash "$cli" plugin install bundled:word-navigation > /dev/null
check_startup 1

# Upgrading a pre-plugin installation seeds the default without touching data.
export POTIONS_HOME="$test_root/Legacy Potions home"
mkdir -p "$POTIONS_HOME/config"
printf '%s\n' '2.18.1' > "$POTIONS_HOME/.version"
printf '%s\n' 'user configuration' > "$POTIONS_HOME/config/local.zsh"
printf '%s\n' 'user history' > "$POTIONS_HOME/.zsh_history"
deploy_runtime
grep -Eq '^word-navigation:active:' "$POTIONS_HOME/plugins/.state"
printf '%s\n' 'user configuration' | assert_same_text - "$POTIONS_HOME/config/local.zsh"
printf '%s\n' 'user history' | assert_same_text - "$POTIONS_HOME/.zsh_history"
printf '%s\n' '2.18.1' | assert_same_text - "$POTIONS_HOME/.version"

# First-time migration preserves an existing user's plugin with the same name.
custom_source="$test_root/custom word navigation"
mkdir -p "$custom_source/config"
cp "$repo_root/plugins/bundled/word-navigation/plugin.potions.json" "$custom_source/"
printf '%s\n' 'export USER_WORD_NAVIGATION=preserved' > "$custom_source/config/init.zsh"
export POTIONS_HOME="$test_root/Existing Potions home"
mkdir -p "$POTIONS_HOME/bin"
cp "$repo_root/.potions/bin/potions" "$POTIONS_HOME/bin/"
cp "$repo_root/.version" "$POTIONS_HOME/.version"
bash "$repo_root/plugins.sh" install "$custom_source" > /dev/null
cp "$POTIONS_HOME/plugins/.state" "$test_root/collision.state"
cp "$POTIONS_HOME/Potionfile.lock" "$test_root/collision.lock"
deploy_runtime
[ "$(readlink "$POTIONS_HOME/plugins/word-navigation")" = "$custom_source" ]
assert_same_text "$test_root/collision.state" "$POTIONS_HOME/plugins/.state"
assert_same_text "$test_root/collision.lock" "$POTIONS_HOME/Potionfile.lock"
grep -Fxq 'export USER_WORD_NAVIGATION=preserved' "$custom_source/config/init.zsh"
bash "$POTIONS_HOME/bin/potions" plugin list | grep -E 'word-navigation.*\(local\)' > /dev/null
bash "$POTIONS_HOME/bin/potions" plugin info word-navigation | grep -Fx 'Type: Local plugin' > /dev/null
grep -Fq "|local:$custom_source" "$POTIONS_HOME/Potionfile.lock"
if bash "$POTIONS_HOME/bin/potions" plugin install bundled:word-navigation > /dev/null 2>&1; then
  printf '%s\n' 'Bundled install replaced an existing user plugin without approval.' >&2
  exit 1
fi
assert_same_text "$test_root/collision.state" "$POTIONS_HOME/plugins/.state"
assert_same_text "$test_root/collision.lock" "$POTIONS_HOME/Potionfile.lock"
if bash "$POTIONS_HOME/bin/potions" plugin install bundled:../word-navigation > /dev/null 2>&1; then
  printf '%s\n' 'Bundled install accepted a path outside its package name.' >&2
  exit 1
fi

if command -v zsh > /dev/null 2>&1; then
  printf '%s\n' 'Bundled plugin lifecycle, user data, and terminal keymap parity passed.'
else
  printf '%s\n' 'Bundled plugin lifecycle and user data passed. Keymap checks require Zsh.'
fi
