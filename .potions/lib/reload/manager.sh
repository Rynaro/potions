#!/bin/bash

# Potions Reload Manager — live surface refresh after theme regeneration.
# Invoked as `potions reload [TARGET]` or sourced by terminal/manager.sh for
# `potions terminal reload`.
#
# PRINCIPLE: regenerate is the contract; live-push is an optimization; the
# matrix is the truth. A user who ignores every live push can finish the
# reload from the matrix's one-line per-surface instructions; reload exits 0
# whenever regeneration succeeded.
#
# Bash 3.2 compatible (macOS default shell): no associative arrays,
# no `declare -A`, no `wait -n`, no `local` at file scope.

# Source-safe guard: when sourced by terminal/manager.sh the functions are
# defined and ready; when executed directly the guard is absent and main runs.
if [ -n "${RELOAD_MANAGER_SOURCED:-}" ]; then
  return 0 2>/dev/null || true
fi

# Only set the flag when being sourced (BASH_SOURCE[0] != $0).
if [ "${BASH_SOURCE[0]}" != "$0" ]; then
  RELOAD_MANAGER_SOURCED=1
fi

set -eo pipefail

RELOAD_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
POTIONS_HOME="${POTIONS_HOME:-$HOME/.potions}"

# Resolve REPO_ROOT when running from a repo checkout (…/.potions/lib/reload).
if [ -z "${REPO_ROOT:-}" ]; then
  REPO_ROOT="$(cd "$RELOAD_LIB_DIR/../../.." 2>/dev/null && pwd || echo "")"
fi

# Logging: minimal, mirrors theme/manager.sh and terminal/manager.sh.
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then HAS_COLOR=true; else HAS_COLOR=false; fi

_rlog() { if [ "$HAS_COLOR" = true ]; then printf "%b%s%b\n" "$2" "$1" "$NC" >&2; else echo "$1" >&2; fi; }
log_info()    { _rlog "$1" "$CYAN"; }
log_success() { _rlog "$1" "$GREEN"; }
log_warning() { _rlog "$1" "$YELLOW"; }
log_error()   { _rlog "$1" "$RED"; }

# --- Scope helpers -----------------------------------------------------------

# Validate that TARGET is a known scope keyword.
# Returns 0 for valid, 1 for invalid.
reload_scope_valid() {
  case "$1" in
    all|terminal|shell|nvim|zellij) return 0 ;;
    *) return 1 ;;
  esac
}

# Echo whether <surface> is in scope for <scope>.
# Usage: reload_in_scope <scope> <surface>  → exits 0 if in scope
reload_in_scope() {
  local scope="$1" surface="$2"
  case "$scope" in
    all)
      # all = [shell, termux, alacritty, wezterm, kitty, ghostty, zellij, nvim]
      case "$surface" in
        shell|termux|alacritty|wezterm|kitty|ghostty|zellij|nvim) return 0 ;;
      esac
      ;;
    terminal)
      # terminal = [shell, termux, alacritty, wezterm, kitty, ghostty]
      case "$surface" in
        shell|termux|alacritty|wezterm|kitty|ghostty) return 0 ;;
      esac
      ;;
    shell)
      [ "$surface" = "shell" ] && return 0
      ;;
    nvim)
      [ "$surface" = "nvim" ] && return 0
      ;;
    zellij)
      [ "$surface" = "zellij" ] && return 0
      ;;
  esac
  return 1
}

# --- Phase 1: Regeneration ---------------------------------------------------

# Resolve the theme manager path (repo checkout first, then installed location).
_reload_theme_manager() {
  if [ -n "${REPO_ROOT:-}" ] && [ -f "$REPO_ROOT/.potions/lib/theme/manager.sh" ]; then
    echo "$REPO_ROOT/.potions/lib/theme/manager.sh"
  elif [ -f "$POTIONS_HOME/lib/theme/manager.sh" ]; then
    echo "$POTIONS_HOME/lib/theme/manager.sh"
  fi
}

# Regenerate ALL surfaces via the theme manager's `regen` subcommand.
# Scope does NOT limit regen — it always regenerates everything.
# Returns non-zero on failure (caller should log_error + exit).
reload_regenerate() {
  local mgr
  mgr="$(_reload_theme_manager)"
  if [ -z "$mgr" ] || [ ! -f "$mgr" ]; then
    log_error "Theme manager not found; cannot regenerate."
    return 1
  fi
  REPO_ROOT="${REPO_ROOT:-}" POTIONS_HOME="$POTIONS_HOME" bash "$mgr" regen
}

# --- Phase 2: Live-push pass -------------------------------------------------

# Per-surface outcome variables (Bash 3.2: positional vars, no assoc arrays).
# Set to one of: live | skipped_multiplexer | skipped_term | auto |
#                needs_action | next | hidden | error
RELOAD_OUT_SHELL=""
RELOAD_OUT_TERMUX=""
RELOAD_OUT_ALACRITTY=""
RELOAD_OUT_WEZTERM=""
RELOAD_OUT_KITTY=""
RELOAD_OUT_GHOSTTY=""
RELOAD_OUT_ZELLIJ=""
RELOAD_OUT_NVIM=""

# Cross-platform bounded exec: run <cmd> [args...] with a watchdog timer.
# Usage: reload_bounded_exec <secs> <cmd> [args...]
# Returns the command's exit code, or 124 on timeout (SIGTERM).
# Per-call ceiling: ≤2s for termux/kitty; hard ceiling 5s.
# Never hangs: watchdog fires even if mktemp/kill/sleep are missing.
reload_bounded_exec() {
  local secs="$1"
  shift
  local pid rc wdpid tmp

  # Temp file to capture output (never leaked to user stdout).
  tmp="$(mktemp 2>/dev/null)" || tmp="/tmp/potions_reload_$$"

  # Run command in background, capturing stdout+stderr to temp file.
  "$@" > "$tmp" 2>&1 &
  pid=$!

  # Background watchdog: sleep then kill if still running.
  # Guard kill with kill -0 to shrink PID-reuse race.
  (
    sleep "$secs" 2>/dev/null || true
    kill -0 "$pid" 2>/dev/null && kill "$pid" 2>/dev/null || true
  ) &
  wdpid=$!

  # Wait for the command to finish. Capture the exit code via `|| rc=$?` so a
  # non-zero status (e.g. 143 when the watchdog SIGTERMs a timed-out command)
  # does not trip `set -e` when this function is called as a bare command —
  # only then does the 143->124 mapping below get a chance to run.
  rc=0
  wait "$pid" 2>/dev/null || rc=$?

  # Kill the watchdog (ignore failure — it may have already exited).
  kill "$wdpid" 2>/dev/null || true
  wait "$wdpid" 2>/dev/null || true

  # Map SIGTERM (143) -> 124 sentinel.
  if [ "$rc" -eq 143 ]; then rc=124; fi

  rm -f "$tmp" 2>/dev/null || true
  return $rc
}

# OSC shell palette push.
# Re-derives the gate: TERM≠dumb/linux AND $ZELLIJ unset AND stdout is a tty.
reload_push_shell() {
  local ansi
  ansi="$POTIONS_HOME/config/generated/ansi-map.sh"

  # Gate: skip if inside a multiplexer.
  if [ -n "${ZELLIJ:-}" ]; then
    RELOAD_OUT_SHELL="skipped_multiplexer"
    return 0
  fi

  # Gate: skip if TERM is dumb or linux (no OSC support).
  case "${TERM:-}" in
    dumb|linux|'')
      RELOAD_OUT_SHELL="skipped_term"
      return 0
      ;;
  esac

  # Gate: skip if stdout is not a tty.
  if ! [ -t 1 ]; then
    RELOAD_OUT_SHELL="skipped_term"
    return 0
  fi

  # All gates passed: emit the OSC palette.
  if [ -f "$ansi" ]; then
    # shellcheck source=/dev/null
    . "$ansi" 2>/dev/null || true
    if command -v potions_apply_terminal_palette > /dev/null 2>&1; then
      potions_apply_terminal_palette
    fi
  fi
  RELOAD_OUT_SHELL="live"
}

# Termux live reload.
# Gate: $TERMUX_VERSION set OR command -v termux-reload-settings.
reload_push_termux() {
  # Hide entirely when not on Termux.
  if [ -z "${TERMUX_VERSION:-}" ] && ! command -v termux-reload-settings > /dev/null 2>&1; then
    RELOAD_OUT_TERMUX="hidden"
    return 0
  fi

  # Attempt bounded reload; non-fatal on failure.
  if reload_bounded_exec 2 termux-reload-settings; then
    RELOAD_OUT_TERMUX="live"
  else
    RELOAD_OUT_TERMUX="needs_action"
  fi
}

# Kitty remote-control push.
# Gate: $KITTY_LISTEN_ON set (no socket discovery, no pgrep).
reload_push_kitty() {
  local conf
  conf="$POTIONS_HOME/config/generated/kitty-colors.conf"

  if [ -z "${KITTY_LISTEN_ON:-}" ]; then
    RELOAD_OUT_KITTY="needs_action"
    return 0
  fi

  if [ ! -f "$conf" ]; then
    RELOAD_OUT_KITTY="needs_action"
    return 0
  fi

  # Bounded exec; non-fatal on failure.
  if reload_bounded_exec 2 kitty @ set-colors -a -c "$conf"; then
    RELOAD_OUT_KITTY="live"
  else
    RELOAD_OUT_KITTY="needs_action"
  fi
}

# Set static outcomes for surfaces that auto-reload or need manual action.
_reload_set_static_outcomes() {
  RELOAD_OUT_ALACRITTY="auto"
  RELOAD_OUT_WEZTERM="auto"
  RELOAD_OUT_GHOSTTY="needs_action"
  RELOAD_OUT_ZELLIJ="next"
  RELOAD_OUT_NVIM="needs_action"
}

# Orchestrate the live-push pass for in-scope surfaces.
reload_push_pass() {
  local scope="$1"

  # Set static outcomes first (for surfaces that need no shell-out).
  _reload_set_static_outcomes

  # Per-surface live attempts (only for surfaces that have a live push).
  if reload_in_scope "$scope" shell; then
    reload_push_shell
  fi
  if reload_in_scope "$scope" termux; then
    reload_push_termux
  fi
  if reload_in_scope "$scope" kitty; then
    reload_push_kitty
  fi
}

# --- Phase 3: Result matrix --------------------------------------------------

# Print the result-aware reload matrix (in-scope surfaces only).
# Termux row hidden when off-Termux. Terminal scope omits nvim & zellij.
reload_print_matrix() {
  local scope="$1"

  echo ""
  if [ "$HAS_COLOR" = true ]; then
    printf "%b%s%b\n" "$CYAN" "Reload complete. Surface status:" "$NC"
  else
    echo "Reload complete. Surface status:"
  fi

  # shell
  if reload_in_scope "$scope" shell; then
    case "$RELOAD_OUT_SHELL" in
      live)
        echo "  Shell palette: live now"
        ;;
      skipped_multiplexer)
        echo "  Shell palette: skipped (multiplexer — open a native pane to repaint)"
        ;;
      skipped_term|*)
        echo "  Shell palette: skipped (TERM=${TERM:-unset})"
        ;;
    esac
  fi

  # termux (hidden when off-Termux)
  if reload_in_scope "$scope" termux && [ "${RELOAD_OUT_TERMUX:-hidden}" != "hidden" ]; then
    case "$RELOAD_OUT_TERMUX" in
      live)         echo "  Termux: live now" ;;
      needs_action) echo "  Termux: needs restart (termux-reload-settings unavailable or failed)" ;;
    esac
  fi

  # alacritty
  if reload_in_scope "$scope" alacritty; then
    echo "  Alacritty: auto-reloaded (Alacritty watches the import)"
  fi

  # wezterm
  if reload_in_scope "$scope" wezterm; then
    echo "  WezTerm: auto-reloaded (WezTerm watches the import)"
  fi

  # kitty
  if reload_in_scope "$scope" kitty; then
    case "$RELOAD_OUT_KITTY" in
      live)         echo "  Kitty: live now" ;;
      needs_action) echo "  Kitty: needs restart (or enable remote control)" ;;
    esac
  fi

  # ghostty
  if reload_in_scope "$scope" ghostty; then
    echo "  Ghostty: needs action — press your Ghostty reload keybind (or restart)"
  fi

  # zellij
  if reload_in_scope "$scope" zellij; then
    echo "  Zellij: applies on next Zellij session"
  fi

  # nvim
  if reload_in_scope "$scope" nvim; then
    echo "  NeoVim: needs action — run :source \$MYVIMRC in nvim (or restart)"
  fi
}

# --- Entry point -------------------------------------------------------------

reload_usage() {
  cat <<'EOF'
potions reload - regenerate all theme artifacts and push live where possible

USAGE:
    potions reload [TARGET]

TARGETS:
    all        Regenerate + push all surfaces (default)
    terminal   Regenerate + push terminal surfaces only (shell, alacritty, etc.)
    shell      Regenerate + push shell palette only
    nvim       Regenerate; print NeoVim reload instruction
    zellij     Regenerate; print Zellij reload instruction

Regeneration always covers all surfaces; TARGET only filters live-push
attempts and matrix output lines.
EOF
}

# Main orchestrator.
# Parses scope, runs phases in order: regen → push → matrix. Exits 0 whenever
# regeneration succeeded; live-push failures never change the exit code.
reload_main() {
  local scope="${1:-all}"
  shift 2>/dev/null || true

  # Validate scope.
  if ! reload_scope_valid "$scope"; then
    log_error "Unknown reload target: $scope"
    echo "" >&2
    reload_usage >&2
    exit 2
  fi

  # Phase 1: Regenerate ALL surfaces (unconditional; scope does not limit this).
  log_info "Regenerating theme artifacts..."
  if ! reload_regenerate; then
    log_error "Theme regeneration failed."
    exit 1
  fi
  log_success "Theme artifacts regenerated."

  # Phase 2: Live-push pass (scoped).
  reload_push_pass "$scope"

  # Phase 3: Print result-aware matrix.
  reload_print_matrix "$scope"

  exit 0
}

# Run main when executed directly (not when sourced).
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  reload_main "$@"
fi
