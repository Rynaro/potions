#!/bin/bash

# Potions Terminal Manager — CLI entry point for terminal-emulator support.
# Invoked as `potions terminal <subcommand>`.
#
# The theme generator owns the *palette* artifacts (config/generated/*, the live
# Termux colors.properties). This module owns the one-time *structural* wiring
# that lives OUTSIDE ~/.potions and therefore must be done deliberately, with a
# backup and full idempotency:
#   - Ghostty: add a `config-file` include to ~/.config/ghostty/config.
#   - Termux:  add a touch-friendly extra-keys row to ~/.termux/termux.properties.
#
# Configure-only: this NEVER installs an emulator. Each target self-gates to the
# platform/emulator that is actually present, so `setup --auto` is safe anywhere.
#
# Bash 3.2 compatible (macOS default shell); no associative arrays.

set -eo pipefail

TERMINAL_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
POTIONS_HOME="${POTIONS_HOME:-$HOME/.potions}"

# Logging: minimal, mirrors theme/manager.sh.
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then HAS_COLOR=true; else HAS_COLOR=false; fi

_tlog() { if [ "$HAS_COLOR" = true ]; then printf "%b%s%b\n" "$2" "$1" "$NC"; else echo "$1"; fi; }
log_info()    { _tlog "$1" "$CYAN"; }
log_success() { _tlog "$1" "$GREEN"; }
log_warning() { _tlog "$1" "$YELLOW"; }
log_error()   { _tlog "$1" "$RED" >&2; }

# --- detection ---------------------------------------------------------------

terminal_is_termux() { [ -n "${PREFIX:-}" ] && [ -x "${PREFIX}/bin/termux-info" ]; }

terminal_config_home() { echo "${XDG_CONFIG_HOME:-$HOME/.config}"; }
terminal_ghostty_config() { echo "$(terminal_config_home)/ghostty/config"; }

# Ghostty is "present" if the binary is on PATH or a config dir already exists.
terminal_has_ghostty() {
  command -v ghostty > /dev/null 2>&1 && return 0
  [ -d "$(terminal_config_home)/ghostty" ]
}

# Back up <file> to <file>.bak once (never clobber an existing backup).
_terminal_backup() {
  local f="$1"
  [ -f "$f" ] || return 0
  [ -f "$f.bak" ] && return 0
  cp "$f" "$f.bak" && log_info "Backed up $f -> $f.bak"
}

# --- Ghostty -----------------------------------------------------------------
# Add `config-file = ?<abs>/ghostty.conf` to the user's Ghostty config. Absolute
# path (robust across Ghostty versions); the `?` prefix makes the include
# optional so removing Potions later does not break Ghostty. Idempotent.
terminal_setup_ghostty() {
  local fragment cfg dir
  fragment="$POTIONS_HOME/config/generated/ghostty.conf"

  if ! terminal_has_ghostty; then
    log_info "Ghostty not detected — skipping (install Ghostty, then re-run)."
    return 0
  fi
  if [ ! -f "$fragment" ]; then
    log_warning "Ghostty fragment missing ($fragment). Run 'potions theme set' first."
    return 0
  fi

  cfg="$(terminal_ghostty_config)"
  dir="$(dirname "$cfg")"
  [ -d "$dir" ] || mkdir -p "$dir"

  if [ -f "$cfg" ] && grep -Fq "config/generated/ghostty.conf" "$cfg" 2>/dev/null; then
    log_success "Ghostty already wired ($cfg)."
    return 0
  fi

  _terminal_backup "$cfg"
  {
    printf '\n# Added by Potions (potions terminal setup): Alchemist'\''s Orchid + QoL.\n'
    printf '# Switch the palette with: potions theme set <variant>\n'
    printf 'config-file = ?%s\n' "$fragment"
  } >> "$cfg"
  log_success "Wired Ghostty: $cfg"
  log_info "Reload Ghostty (Cmd/Ctrl+Shift+,) or restart it to apply."
}

# --- Termux ------------------------------------------------------------------
# Append a touch-friendly extra-keys row to ~/.termux/termux.properties if the
# user has not set one. Colors are owned by the theme adapter
# (~/.termux/colors.properties); here we just (re)apply settings live.
terminal_setup_termux() {
  local props
  props="$HOME/.termux/termux.properties"

  if ! terminal_is_termux; then
    log_info "Not running in Termux — skipping."
    return 0
  fi

  [ -d "$HOME/.termux" ] || mkdir -p "$HOME/.termux"

  if [ -f "$props" ] && grep -Eq '^[[:space:]]*extra-keys[[:space:]]*=' "$props" 2>/dev/null; then
    log_success "Termux extra-keys already configured ($props)."
  else
    _terminal_backup "$props"
    {
      printf '\n### Added by Potions (potions terminal setup): touch-friendly keys.\n'
      printf 'extra-keys = [ \\\n'
      printf "  ['ESC','/','-','HOME','UP','END','PGUP'], \\\\\n"
      printf "  ['TAB','CTRL','ALT','LEFT','DOWN','RIGHT','PGDN'] \\\\\n"
      printf ']\n'
    } >> "$props"
    log_success "Configured Termux extra-keys: $props"
  fi

  # Apply settings (extra-keys + the theme's colors.properties) live.
  command -v termux-reload-settings > /dev/null 2>&1 && \
    termux-reload-settings > /dev/null 2>&1 || true
  log_info "Applied via termux-reload-settings."
}

# --- dispatchers -------------------------------------------------------------

# Set up every emulator that is actually present (safe on any platform).
terminal_setup_auto() {
  terminal_has_ghostty && terminal_setup_ghostty
  terminal_is_termux   && terminal_setup_termux
  return 0
}

terminal_cmd_setup() {
  local target="${1:-all}"
  case "$target" in
    ghostty)   terminal_setup_ghostty ;;
    termux)    terminal_setup_termux ;;
    all)       terminal_setup_ghostty; terminal_setup_termux ;;
    --auto|auto) terminal_setup_auto ;;
    *)
      log_error "Unknown setup target: $target (use: ghostty | termux | all | --auto)"
      return 1
      ;;
  esac
}

terminal_cmd_status() {
  local cfg
  echo "Terminal emulator support:"
  echo ""

  cfg="$(terminal_ghostty_config)"
  if terminal_has_ghostty; then
    if [ -f "$cfg" ] && grep -Fq "config/generated/ghostty.conf" "$cfg" 2>/dev/null; then
      log_success "Ghostty: detected, wired ($cfg)"
    else
      log_warning "Ghostty: detected, NOT wired — run 'potions terminal setup ghostty'"
    fi
  else
    log_info "Ghostty: not detected"
  fi

  if terminal_is_termux; then
    if [ -f "$HOME/.termux/colors.properties" ]; then
      log_success "Termux: colors applied (~/.termux/colors.properties)"
    else
      log_warning "Termux: colors missing — run 'potions theme set'"
    fi
    if grep -Eq '^[[:space:]]*extra-keys[[:space:]]*=' "$HOME/.termux/termux.properties" 2>/dev/null; then
      log_success "Termux: extra-keys configured"
    else
      log_warning "Termux: extra-keys not set — run 'potions terminal setup termux'"
    fi
  else
    log_info "Termux: not running in Termux"
  fi
}

terminal_cmd_help() {
  cat <<'EOF'
potions terminal - configure supported terminal emulators

USAGE:
    potions terminal <command>

COMMANDS:
    setup [ghostty|termux|all]   Wire the active theme + QoL into the emulator
    setup --auto                 Wire only emulators that are present (safe anywhere)
    status                       Show detected emulators and whether each is wired
    help                         Show this message

Potions never installs an emulator; it only configures one that is present.
Colors follow `potions theme set|cycle` automatically.
EOF
}

main() {
  local command="${1:-status}"
  shift || true
  case "$command" in
    setup)          terminal_cmd_setup "$@" ;;
    status)         terminal_cmd_status ;;
    help|--help|-h) terminal_cmd_help ;;
    *)
      log_error "Unknown terminal command: $command"
      echo ""
      terminal_cmd_help
      exit 1
      ;;
  esac
}

main "$@"
