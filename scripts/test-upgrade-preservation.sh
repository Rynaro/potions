#!/bin/bash

# Exercise the public upgrade command using a local Git remote and disposable home.
set -eo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT
test_home="$test_dir/home with spaces"
install_dir="$test_home/.potions"
upstream="$test_dir/upstream"
templates="$upstream/.potions"
mkdir -p "$install_dir"/{config,nvim,zellij} "$templates"/{config,nvim,zellij}

printf '%s\n' '1.10.0' > "$upstream/.version"
printf '%s\n' '1.9.0' > "$install_dir/.version"
for file in config/{aliases,local,secure}.zsh nvim/user.vim zellij/user.kdl .zsh_aliases notes.md; do
  printf 'user %s\n' "$file" > "$install_dir/$file"
  printf 'template %s\n' "$file" > "$templates/$file"
done
printf '%s\n' 'previous settings' > "$install_dir/zellij/config.kdl"
printf '%s\n' 'new bindings' > "$templates/zellij/config.kdl"
printf '%s\n' 'Linux defaults' > "$templates/config/linux.zsh"
printf '%s\n' 'machine defaults' > "$templates/config/macos.zsh"
ln -s "$test_home/unavailable-config" "$install_dir/config/macos.zsh"

git -c init.defaultBranch=main init -q "$upstream"
git -C "$upstream" add -f .version .potions
git -C "$upstream" -c user.name=Potions -c user.email=tests@localhost \
  -c commit.gpgsign=false -c core.hooksPath=/dev/null commit -qm 'Upgrade fixtures'
git clone -q --local "$upstream" "$install_dir/.repo"
cd "$test_dir"

run_upgrade() {
  if ! env HOME="$test_home" bash "$repo_root/upgrade.sh" > "$test_dir/log" 2>&1; then
    cat "$test_dir/log" >&2
    return 1
  fi
}

run_upgrade
backups=("$install_dir"/backups/backup-*)
[ "${#backups[@]}" -eq 1 ]
[ -d "${backups[0]}" ]
for file in config/{aliases,local,secure}.zsh nvim/user.vim zellij/user.kdl .zsh_aliases notes.md; do
  printf 'user %s\n' "$file" | cmp - "$install_dir/$file"
  cmp "$install_dir/$file" "${backups[0]}/$file"
done
cmp "$templates/config/linux.zsh" "$install_dir/config/linux.zsh"
[ -L "$install_dir/config/macos.zsh" ]
[ ! -e "$test_home/unavailable-config" ]
cmp "$templates/zellij/config.kdl" "$install_dir/zellij/config.kdl"
printf '%s\n' 'previous settings' | cmp - "${backups[0]}/zellij/config.kdl"
cmp "$upstream/.version" "$install_dir/.version"

# Same-version upgrades must leave both managed files and backup history alone.
printf '%s\n' 'second run marker' > "$install_dir/zellij/config.kdl"
run_upgrade
printf '%s\n' 'second run marker' | cmp - "$install_dir/zellij/config.kdl"
backups=("$install_dir"/backups/backup-*)
[ "${#backups[@]}" -eq 1 ]

# A sixth backup prunes just the oldest directory, including in a spaced home.
mkdir "$install_dir"/backups/backup-2000010{1,2,3,4}-000000 "$test_dir/home"
printf '%s\n' '1.11.0' > "$upstream/.version"
git -C "$upstream" -c user.name=Potions -c user.email=tests@localhost \
  -c commit.gpgsign=false -c core.hooksPath=/dev/null commit -qam 'Next version'
run_upgrade
backups=("$install_dir"/backups/backup-*)
[ "${#backups[@]}" -eq 5 ]
[ ! -e "$install_dir/backups/backup-20000101-000000" ]
[ -d "$install_dir/backups/backup-20000102-000000" ]
[ -d "$test_dir/home" ]
printf '%s\n' 'Upgrade preserved user files, installed new defaults and skipped a repeat run.'
