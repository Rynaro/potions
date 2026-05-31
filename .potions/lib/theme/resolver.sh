#!/bin/bash

# Potions Theme Resolver (C5)
# The ONLY component that reads .theme file contents. Owns the trust boundary.
#
# .theme files are NEVER sourced. Every line is validated against a strict
# whitelist and rejected on any non-matching line, so a hostile token file
# (e.g. COLOR_X_HEX=$(rm -rf ~)) is refused, never executed. Validated values
# are assigned via `printf -v` into shell variables named exactly by the key,
# which performs no command/arithmetic expansion.
#
# Bash 3.2 compatible (no associative arrays; no `declare -A`).

# Guard against multiple inclusion
if [ -n "${THEME_RESOLVER_SOURCED:-}" ]; then
  return 0
fi
THEME_RESOLVER_SOURCED=1

# Whitelist patterns (kept in variables to avoid quoting hazards).
# token: COLOR_/COMPONENT_ key, value is a #RRGGBB hex or a 0-255 integer.
# meta:  META_ key, value is a restricted, shell-metacharacter-free string.
THEME_TOKEN_RE='^(COLOR|COMPONENT)_[A-Z0-9_]+_(HEX|CTERM)=([#][0-9A-Fa-f]{6}|[0-9]{1,3})$'
THEME_META_RE='^META_[A-Z0-9_]+=[A-Za-z0-9 ,._'\''-]*$'

# Accumulator of token keys assigned during the most recent resolve.
THEME_RESOLVED_KEYS=""

# Load and validate a single .theme file into shell variables.
# Returns non-zero (and assigns nothing further) on the first rejected line.
# Usage: theme_resolver_load <theme_file>
theme_resolver_load() {
  local file="$1"
  local line key val lineno=0

  if [ ! -f "$file" ]; then
    echo "theme: file not found: $file" >&2
    return 1
  fi

  while IFS= read -r line || [ -n "$line" ]; do
    lineno=$((lineno + 1))
    line="${line%$'\r'}"  # tolerate CRLF

    case "$line" in
      ''|\#*) continue ;;
    esac

    if printf '%s\n' "$line" | grep -Eq "$THEME_TOKEN_RE"; then
      key="${line%%=*}"
      val="${line#*=}"
      case "$key" in
        *_CTERM)
          if ! [ "$val" -ge 0 ] 2>/dev/null || ! [ "$val" -le 255 ] 2>/dev/null; then
            echo "theme: $file:$lineno cterm out of range (0-255): $line" >&2
            return 1
          fi
          ;;
      esac
      printf -v "$key" '%s' "$val"
      THEME_RESOLVED_KEYS="$THEME_RESOLVED_KEYS $key"
    elif printf '%s\n' "$line" | grep -Eq "$THEME_META_RE"; then
      key="${line%%=*}"
      val="${line#*=}"
      printf -v "$key" '%s' "$val"
    else
      echo "theme: $file:$lineno rejected (not a valid token/meta line): $line" >&2
      return 1
    fi
  done < "$file"

  return 0
}

# Read a single META_BASE pointer from a .theme without full validation.
# Only ever returns a value that matches the safe meta charset.
# Usage: theme_resolver_base <theme_file>
theme_resolver_base() {
  local file="$1" base
  [ -f "$file" ] || return 0
  base="$(grep -E '^META_BASE=[A-Za-z0-9._-]+$' "$file" 2>/dev/null | head -1)"
  base="${base#META_BASE=}"
  printf '%s' "$base"
}

# Resolve a theme variant into shell variables, applying base inheritance.
# Loads <base>.theme first (if META_BASE is set), then <variant>.theme so the
# variant overrides shared tokens. Inheritance is resolved HERE, never by an
# in-file `source`, so BYO themes can inherit without us executing them.
# Usage: theme_resolve <theme_dir> <variant>
theme_resolve() {
  local theme_dir="$1" variant="$2"
  local vfile bfile base

  vfile="$theme_dir/$variant.theme"
  if [ ! -f "$vfile" ]; then
    echo "theme: variant '$variant' not found in $theme_dir" >&2
    return 1
  fi

  THEME_RESOLVED_KEYS=""

  base="$(theme_resolver_base "$vfile")"
  if [ -n "$base" ]; then
    bfile="$theme_dir/$base.theme"
    if [ -f "$bfile" ]; then
      theme_resolver_load "$bfile" || return 1
    fi
  fi

  theme_resolver_load "$vfile" || return 1
  return 0
}
