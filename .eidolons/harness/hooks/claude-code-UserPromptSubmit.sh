#!/usr/bin/env bash
# Eidolons harness shim — UserPromptSubmit
# Hook failure policy is generated from eidolons.yaml at install time.
# R21: #16952 guard — skip kernel when prompt is a task-completion notification.
# (Claude bug: UserPromptSubmit also fires on Task/subagent completion; conservative
#  best-effort heuristic; fail-open: false-positive = one skipped inject, harmless.)
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

_bin="$(_eidolons_bin 2>/dev/null)" || { _eidolons_hook_fail UserPromptSubmit missing-cli; exit 0; }
# Read stdin into a variable (hook passes event JSON on stdin).
_input="$(cat 2>/dev/null)" || { _eidolons_hook_fail UserPromptSubmit input-error; exit 0; }
if ! command -v jq >/dev/null 2>&1 || ! printf '%s' "$_input" | jq -e 'type == "object" and (.prompt | type == "string")' >/dev/null 2>&1; then
  _eidolons_hook_fail UserPromptSubmit malformed-input; exit 0
fi
_prompt="$(printf '%s' "$_input" | jq -r '.prompt')"
[[ -n "$_prompt" ]] || { _eidolons_hook_fail UserPromptSubmit empty-prompt; exit 0; }
# #16952 guard: skip kernel when the prompt is a task-completion notification.
case "$_prompt" in
  "Agent "*" completed"*) exit 0 ;;
  *"<task-notification>"*) exit 0 ;;
esac
_out="$("$_bin" run --hook claude-code --stdin <<< "$_input" 2>/dev/null)" || { _eidolons_hook_fail UserPromptSubmit kernel-error; exit 0; }
if [[ -z "$_out" ]] && [[ "$_eidolons_hook_policy" != "fail-closed" ]] && ! _eidolons_hook_qualified "$_prompt"; then exit 0; fi
_eidolons_hook_valid UserPromptSubmit "$_out" || { _eidolons_hook_fail UserPromptSubmit empty-or-invalid-output; exit 0; }
printf '%s\n' "$_out"
