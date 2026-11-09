#!/usr/bin/env bash
# Eidolons harness shim — SessionStart
# Hook failure policy is generated from eidolons.yaml at install time.
set -euo pipefail

cd "${CLAUDE_PROJECT_DIR:-$PWD}" 2>/dev/null || exit 0
. "$(dirname "$0")/eidolons-hook-policy.sh"

_eidolons_bin() {
  if command -v eidolons >/dev/null 2>&1; then
    echo "eidolons"
  elif [[ -x "${EIDOLONS_HOME:-$HOME/.eidolons}/nexus/cli/eidolons" ]]; then
    echo "${EIDOLONS_HOME:-$HOME/.eidolons}/nexus/cli/eidolons"
  else
    return 1
  fi
}

_bin="$(_eidolons_bin 2>/dev/null)" || { _eidolons_hook_fail SessionStart missing-cli; exit 0; }
_out="$("$_bin" run --hook claude-code --session-start 2>/dev/null)" || { _eidolons_hook_fail SessionStart kernel-error; exit 0; }
_eidolons_hook_valid SessionStart "$_out" || { _eidolons_hook_fail SessionStart empty-or-invalid-output; exit 0; }
printf '%s\n' "$_out"
