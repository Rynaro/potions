#!/bin/bash
# Deploy plugin manager code exclusively beneath the managed library directory.
install_plugin_runtime() {
  local repo_root="$1" potions_root="$2" stage target
  target="$potions_root/lib/plugin-manager"
  mkdir -p "$potions_root/lib" || return 1
  stage=$(mktemp -d "$potions_root/lib/.plugin-manager.XXXXXX") || return 1
  mkdir -p "$stage/packages" "$stage/plugins/registry" || return 1
  if ! cp "$repo_root/plugins.sh" "$repo_root/.version" "$stage/" ||
     ! cp "$repo_root/packages/accessories.sh" "$stage/packages/" ||
     ! cp -R "$repo_root/plugins/core" "$stage/plugins/core" ||
     ! cp "$repo_root/plugins/scaffold_plugin.sh" "$stage/plugins/" ||
     ! cp "$repo_root/plugins/registry/verified.txt" "$stage/plugins/registry/"; then
    rm -rf "$stage"
    return 1
  fi
  if [ -e "$target" ] || [ -L "$target" ]; then
    local backup_root
    backup_root=$(mktemp -d "$potions_root/lib/.plugin-manager-backup.XXXXXX") || return 1
    mv "$target" "$backup_root/runtime" || return 1
    if ! mv "$stage" "$target"; then
      mv "$backup_root/runtime" "$target"
      return 1
    fi
    rm -rf "$backup_root"
  else
    mv "$stage" "$target" || return 1
  fi
}
