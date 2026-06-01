#!/bin/bash

# Potions Theme State Store (C3)
# Single source of truth for the active theme + variant.
# State lives in $POTIONS_HOME/config/theme.conf as "<theme>:<variant>".
# Backward compatible with the legacy single-token form ("alchemists-orchid").

# Guard against multiple inclusion
if [ -n "${THEME_STATE_SOURCED:-}" ]; then
  return 0
fi
THEME_STATE_SOURCED=1

THEME_DEFAULT_ID="alchemists-orchid"
THEME_DEFAULT_VARIANT="dark"

theme_state_file() {
  echo "${POTIONS_HOME:-$HOME/.potions}/config/theme.conf"
}

# Echo the raw "<theme>:<variant>" active state, applying defaults and
# migrating the legacy single-token format. Always succeeds.
theme_state_read() {
  local file raw theme variant
  file="$(theme_state_file)"

  if [ ! -f "$file" ]; then
    echo "$THEME_DEFAULT_ID:$THEME_DEFAULT_VARIANT"
    return 0
  fi

  raw="$(head -1 "$file" 2>/dev/null | tr -d '[:space:]')"

  if [ -z "$raw" ]; then
    echo "$THEME_DEFAULT_ID:$THEME_DEFAULT_VARIANT"
    return 0
  fi

  case "$raw" in
    *:*)
      theme="${raw%%:*}"
      variant="${raw#*:}"
      ;;
    *)
      # Legacy single-token form -> assume default variant
      theme="$raw"
      variant="$THEME_DEFAULT_VARIANT"
      ;;
  esac

  [ -n "$theme" ] || theme="$THEME_DEFAULT_ID"
  [ -n "$variant" ] || variant="$THEME_DEFAULT_VARIANT"
  echo "$theme:$variant"
}

theme_state_theme() {
  theme_state_read | cut -d: -f1
}

theme_state_variant() {
  theme_state_read | cut -d: -f2
}

# Persist the active theme + variant, backing up any existing state file.
# (Consumed by `potions theme set` in Phase 1; read-only commands do not call it.)
# Usage: theme_state_write <theme> <variant>
theme_state_write() {
  local theme="$1" variant="$2" file dir
  file="$(theme_state_file)"
  dir="$(dirname "$file")"

  [ -d "$dir" ] || mkdir -p "$dir"
  if [ -f "$file" ]; then
    cp "$file" "$file.backup" 2>/dev/null || true
  fi
  printf '%s:%s\n' "$theme" "$variant" > "$file"
}
