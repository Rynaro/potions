#!/bin/bash

# Actions run from the directory in which the Desk was opened.
desk_working_tree() {
  if ! command -v git >/dev/null 2>&1; then
    printf '%s\n' 'Git is unavailable. Install Git to see changes here.'
    return
  fi

  if [ "$(git rev-parse --is-inside-work-tree 2>/dev/null)" != true ]; then
    printf '%s\n' 'Open the Desk from a Git working tree to see local changes.'
    return
  fi

  local status_lines headline changes commit
  # Porcelain v1 C-quotes unusual filenames. Disable optional index refreshes,
  # paging, color and filesystem-monitor hooks for this read-only snapshot.
  if ! status_lines=$(LC_ALL=C GIT_OPTIONAL_LOCKS=0 git --no-pager \
      -c color.ui=false -c core.quotePath=true -c core.fsmonitor=false \
      status --porcelain=v1 --branch --untracked-files=normal 2>/dev/null); then
    printf '%s\n' 'Could not read this working tree. Run git status for details.'
    return
  fi
  headline="${status_lines%%$'\n'*}"
  headline="${headline#\#\# }"
  case "$headline" in
    'HEAD (no branch)')
      commit=$(git rev-parse --short HEAD 2>/dev/null) || commit=HEAD
      printf 'Detached at %s\n' "$commit"
      ;;
    'No commits yet on '*|'Initial commit on '*) printf '%s\n' "$headline" ;;
    *) printf 'Branch  %s\n' "$headline" ;;
  esac
  printf '\n'
  if [[ "$status_lines" == *$'\n'* ]]; then
    changes="${status_lines#*$'\n'}"
    printf '%s\n%s\n\n%s\n' 'Left column: staged   Right: unstaged' '??  Untracked file' "$changes"
  else
    printf '%s\n' 'Working tree is clean.'
  fi
}

desk_report() {
  case "$1" in
    git) desk_working_tree ;;
    doctor)
      # The Desk supplies the heading. Keep the CLI findings from both streams,
      # including when the health check exits with outstanding issues.
      { (HAS_COLOR=false cmd_doctor) 2>&1 || :; } |
        awk 'NF && !/^=+$/ && $0 != "  Potions Health Check"'
      ;;
    *) return 1 ;;
  esac
}

desk_new_tab() {
  if [ -z "${ZELLIJ:-}" ] || ! command -v zellij >/dev/null 2>&1; then
    printf '%s\n' 'Open the Desk inside Zellij to create a project tab.' >&2
    return 1
  fi
  # Zellij 0.41 requires a layout with --cwd. Use the one shipped alongside
  # this library so that opening a tab works from a checkout and an install.
  local layout="${BASH_SOURCE[0]%/*}/../zellij/layouts/compact.kdl"
  if ! zellij action new-tab --cwd "$PWD" --layout "$layout" >/dev/null 2>&1; then
    printf '%s\n' 'Zellij could not open a tab in this directory.' >&2
    return 1
  fi
}

desk_edit() (
  local editor_spec editor_cmd target
  local -a editor_args
  editor_spec="${VISUAL:-${EDITOR:-}}"
  if [ -z "$editor_spec" ]; then
    if type -P nvim >/dev/null; then
      editor_spec="nvim"
    else
      editor_spec="vi"
    fi
  fi
  # An entire executable path may contain spaces. Otherwise accept a command
  # with whitespace-separated arguments; use a wrapper for shell syntax.
  if editor_cmd=$(type -P -- "$editor_spec"); then
    editor_args=("$editor_cmd")
  else
    IFS=$' \t' read -r -a editor_args <<< "$editor_spec"
    if ! editor_cmd=$(type -P -- "${editor_args[0]:-}"); then
      printf '%s\n' 'Editor unavailable. Set VISUAL or EDITOR to an executable.' >&2
      return 1
    fi
    editor_args[0]="$editor_cmd"
  fi

  case "$1" in
    edit) target=. ;;
    notes)
      local notes_dir="$POTIONS_HOME"
      [[ "$notes_dir" = /* ]] || notes_dir="$PWD/$notes_dir"
      umask 077
      if ! mkdir -p "$notes_dir"; then
        printf '%s\n' 'Could not open the scratchpad directory.' >&2
        return 1
      fi
      target="$notes_dir/notes.md"
      if { [ -e "$target" ] || [ -L "$target" ]; } && [ ! -f "$target" ]; then
        printf '%s\n' 'The scratchpad path must point to a regular file.' >&2
        return 1
      fi
      # The editor creates the file on first save and handles concurrent edits.
      ;;
    *) return 1 ;;
  esac
  if ! "${editor_args[@]}" "$target"; then
    printf '%s\n' 'The editor exited with an error.' >&2
    return 1
  fi
)
