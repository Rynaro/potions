#!/bin/bash

# Potions Theme Registry (C6, discovery side)
# Locates installed themes and reads their manifests. A theme directory is any
# directory under a themes root that contains a `manifest` file. Manifests are
# flat KEY=value and are read with grep/cut only — never sourced.
#
# Phase 0 discovers built-in themes shipped under .potions/themes. Plugin-
# provided theme directories are added in a later phase.

# Guard against multiple inclusion
if [ -n "${THEME_REGISTRY_SOURCED:-}" ]; then
  return 0
fi
THEME_REGISTRY_SOURCED=1

# Echo the active built-in themes root directory (repo checkout or install).
theme_registry_root() {
  if [ -n "${THEME_REGISTRY_ROOT:-}" ]; then
    echo "$THEME_REGISTRY_ROOT"
    return 0
  fi
  if [ -n "${REPO_ROOT:-}" ] && [ -d "$REPO_ROOT/.potions/themes" ]; then
    echo "$REPO_ROOT/.potions/themes"
  elif [ -d "${POTIONS_HOME:-$HOME/.potions}/themes" ]; then
    echo "${POTIONS_HOME:-$HOME/.potions}/themes"
  fi
}

# Read one manifest field. Usage: theme_registry_field <manifest> <KEY>
theme_registry_field() {
  local manifest="$1" key="$2" line
  [ -f "$manifest" ] || return 1
  line="$(grep -E "^${key}=" "$manifest" 2>/dev/null | head -1)"
  [ -n "$line" ] || return 1
  printf '%s' "${line#*=}"
}

# Echo the directory of a theme by id, or return non-zero.
# Usage: theme_registry_find <theme_id>
theme_registry_find() {
  local id="$1" root dir mid
  root="$(theme_registry_root)"
  [ -n "$root" ] || return 1

  for dir in "$root"/*/; do
    [ -d "$dir" ] || continue
    [ -f "${dir}manifest" ] || continue
    mid="$(theme_registry_field "${dir}manifest" META_ID || true)"
    [ -n "$mid" ] || mid="$(basename "$dir")"
    if [ "$mid" = "$id" ]; then
      printf '%s' "${dir%/}"
      return 0
    fi
  done
  return 1
}

# List installed themes as "id|name|variants|trust" lines.
theme_registry_list() {
  local root dir manifest id name variants trust
  root="$(theme_registry_root)"
  [ -n "$root" ] || return 0

  for dir in "$root"/*/; do
    [ -d "$dir" ] || continue
    manifest="${dir}manifest"
    [ -f "$manifest" ] || continue
    id="$(theme_registry_field "$manifest" META_ID || basename "$dir")"
    name="$(theme_registry_field "$manifest" META_NAME || echo "$id")"
    variants="$(theme_registry_field "$manifest" META_VARIANTS || echo "")"
    trust="$(theme_registry_field "$manifest" META_TRUST || echo "builtin")"
    printf '%s|%s|%s|%s\n' "$id" "$name" "$variants" "$trust"
  done
}

# Echo the display name for a theme id (falls back to the id).
# Usage: theme_registry_name <theme_id>
theme_registry_name() {
  local id="$1" dir
  dir="$(theme_registry_find "$id" 2>/dev/null || true)"
  if [ -n "$dir" ] && [ -f "$dir/manifest" ]; then
    theme_registry_field "$dir/manifest" META_NAME || printf '%s' "$id"
  else
    printf '%s' "$id"
  fi
}
