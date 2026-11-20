#!/bin/bash

# Each pin is a symlink to a physical directory. Its content-derived name makes
# pin/unpin atomic and independent across processes, even for stale targets.
_desk_project_check_path() {
  if [[ -z "$1" || "$1" == *[[:cntrl:]]* ]]; then
    printf 'Choose a directory path without control characters.\n' >&2
    return 1
  fi
}

_desk_project_record() {
  local digest
  if command -v sha256sum >/dev/null 2>&1; then
    digest=$(printf '%s' "$1" | sha256sum) || return 1
  elif command -v shasum >/dev/null 2>&1; then
    digest=$(printf '%s' "$1" | shasum -a 256) || return 1
  else
    printf 'Project pins require sha256sum or shasum.\n' >&2
    return 1
  fi
  printf '%s/projects.d/%s.pin' "$POTIONS_HOME" "${digest%% *}"
}

_desk_project_store_ok() {
  local store="$POTIONS_HOME/projects.d"
  if [ -L "$store" ] || { [ -e "$store" ] && ! [ -d "$store" ]; }; then
    printf 'The project pin store must be a directory.\n' >&2
    return 1
  fi
}

desk_project_pin() (
  local path="${1-.}" record
  if [ "$#" -gt 1 ]; then
    printf 'Usage: potions projects pin [DIR]\n' >&2
    return 2
  fi
  _desk_project_check_path "$path" || return 1
  [[ "$path" == /* ]] || path="./$path"
  if ! cd -P -- "$path" 2>/dev/null; then
    printf 'Choose an existing, accessible directory to pin.\n' >&2
    return 1
  fi
  path="$PWD"
  _desk_project_check_path "$path" || return 1
  record=$(_desk_project_record "$path") || return 1
  _desk_project_store_ok || return 1
  umask 077
  mkdir -p "$POTIONS_HOME/projects.d" || return 1
  # -n prevents ln from traversing an existing pin into the project itself.
  if ! [ -d "$record" ] && ln -sn "$path" "$record" 2>/dev/null; then return 0; fi
  if [ -L "$record" ] && [ "$(readlink "$record")" = "$path" ]; then return 0; fi
  printf 'Could not save the project pin.\n' >&2
  return 1
)

desk_project_unpin() (
  local path="${1-}" parent suffix record candidate
  local -a candidates
  if [ "$#" -ne 1 ]; then
    printf 'Usage: potions projects unpin PATH\n' >&2
    return 2
  fi
  _desk_project_check_path "$path" || return 1
  _desk_project_store_ok || return 1
  [ -d "$POTIONS_HOME/projects.d" ] || return 0
  [[ "$path" == /* ]] || path="${PWD%/}/${path#./}"
  while [[ "$path" != / && "$path" == */ ]]; do path="${path%/}"; done

  # Try the listed spelling first, even if it now points somewhere else.
  candidates=("$path")
  parent="${path%/*}"
  suffix="${path##*/}"
  while [ -n "$parent" ] && ! [ -d "$parent" ]; do
    suffix="${parent##*/}/$suffix"
    parent="${parent%/*}"
  done
  if cd -P -- "${parent:-/}" 2>/dev/null; then
    # A symlinked ancestor may still exist after the pinned folder disappears.
    candidate="${PWD%/}/$suffix"
    [ "$candidate" = "$path" ] || candidates+=("$candidate")
  fi
  # Dot segments designate a directory itself. A final symlink, in contrast,
  # may be a replaced pin and must never cause removal of its new target.
  if [[ "${path##*/}" = . || "${path##*/}" = .. ]] && cd -P -- "$path" 2>/dev/null; then
    candidates+=("$PWD")
  fi
  for candidate in "${candidates[@]}"; do
    record=$(_desk_project_record "$candidate") || return 1
    if [ -L "$record" ] && [ "$(readlink "$record")" = "$candidate" ]; then
      rm -f "$record"
      return
    elif [ -e "$record" ] || [ -L "$record" ]; then
      printf 'The project pin record is invalid.\n' >&2
      return 1
    fi
  done
  return 0
)

# Plain output is the CLI's line-oriented interface. The Desk consumes NUL
# records to read each complete path independently of whitespace.
desk_project_list() {
  local store="$POTIONS_HOME/projects.d" record expected path
  _desk_project_store_ok || return 1
  [ -d "$store" ] || return 0
  if ! [ -r "$store" ] || ! [ -x "$store" ]; then
    printf 'Cannot read the project pin store.\n' >&2
    return 1
  fi
  for record in "$store"/*.pin; do
    [ -L "$record" ] || continue
    path=$(readlink "$record") || continue
    if [[ "$path" == /* && "$path" != *[[:cntrl:]]* ]]; then
      expected=$(_desk_project_record "$path") || return 1
      if [ "$record" = "$expected" ]; then printf '%s\n' "$path"; fi
    fi
  done | LC_ALL=C sort
}

desk_project_paths() {
  desk_project_list | tr '\n' '\000'
}
