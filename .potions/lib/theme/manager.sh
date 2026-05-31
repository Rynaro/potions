#!/bin/bash

# Potions Theme Manager (C4) — CLI entry point
# Single authority for theme state. Invoked as `potions theme <subcommand>`.
#
# Phase 0 surface: current, list, help.
# Phase 1 adds: set, cycle (regenerate + hot-reload + restart matrix).

set -eo pipefail

THEME_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
POTIONS_HOME="${POTIONS_HOME:-$HOME/.potions}"

# Resolve REPO_ROOT when running from a repo checkout (…/.potions/lib/theme).
if [ -z "${REPO_ROOT:-}" ]; then
  REPO_ROOT="$(cd "$THEME_LIB_DIR/../../.." 2>/dev/null && pwd || echo "")"
fi

# Logging: reuse accessories.sh log_* when available, else minimal fallbacks.
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; MAGENTA='\033[0;35m'; BOLD='\033[1m'; NC='\033[0m'
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then HAS_COLOR=true; else HAS_COLOR=false; fi

_tlog() { if [ "$HAS_COLOR" = true ]; then printf "%b%s%b\n" "$2" "$1" "$NC"; else echo "$1"; fi; }
log_info()    { _tlog "$1" "$CYAN"; }
log_success() { _tlog "$1" "$GREEN"; }
log_warning() { _tlog "$1" "$YELLOW"; }
log_error()   { _tlog "$1" "$RED" >&2; }

# Load sibling modules.
# shellcheck source=/dev/null
. "$THEME_LIB_DIR/resolver.sh"
# shellcheck source=/dev/null
. "$THEME_LIB_DIR/state.sh"
# shellcheck source=/dev/null
. "$THEME_LIB_DIR/registry.sh"
# shellcheck source=/dev/null
. "$THEME_LIB_DIR/generator.sh"

# --- Subcommands ---------------------------------------------------------

theme_cmd_current() {
  local theme variant name
  theme="$(theme_state_theme)"
  variant="$(theme_state_variant)"
  name="$(theme_registry_name "$theme" 2>/dev/null || echo "$theme")"

  if [ "$HAS_COLOR" = true ]; then
    printf "%b%s%b %b(%s)%b\n" "$MAGENTA$BOLD" "$name" "$NC" "$CYAN" "$variant" "$NC"
  else
    echo "$name ($variant)"
  fi
}

theme_cmd_list() {
  local active_theme active_variant line id name variants trust marker
  active_theme="$(theme_state_theme)"
  active_variant="$(theme_state_variant)"

  local listing
  listing="$(theme_registry_list || true)"
  if [ -z "$listing" ]; then
    log_warning "No themes found."
    log_info "Built-in themes live under: $(theme_registry_root 2>/dev/null || echo '<themes root not found>')"
    return 0
  fi

  echo "Installed themes:"
  echo ""
  while IFS='|' read -r id name variants trust; do
    [ -n "$id" ] || continue
    if [ "$id" = "$active_theme" ]; then
      marker="*"
    else
      marker=" "
    fi
    if [ "$HAS_COLOR" = true ]; then
      printf "  %s %b%-22s%b %-26s [%s]\n" "$marker" "$MAGENTA" "$name" "$NC" "variants: ${variants:-none}" "$trust"
    else
      printf "  %s %-22s %-26s [%s]\n" "$marker" "$name" "variants: ${variants:-none}" "$trust"
    fi
    if [ "$id" = "$active_theme" ]; then
      printf "      active variant: %s\n" "$active_variant"
    fi
  done <<EOF
$listing
EOF
}

theme_cmd_help() {
  cat <<'EOF'
potions theme - manage the Potions colorscheme

USAGE:
    potions theme <command>

COMMANDS:
    current            Show the active theme and variant
    list               List installed themes and their variants
    help               Show this message

    set <theme> [variant]   (coming in Phase 1)
    cycle                   (coming in Phase 1)
EOF
}

theme_cmd_pending() {
  log_warning "'$1' arrives in Phase 1 (generator + adapters + hot-reload)."
  log_info "Phase 0 provides: current, list."
  return 2
}

main() {
  local command="${1:-current}"
  case "$command" in
    current)        theme_cmd_current ;;
    list|ls)        theme_cmd_list ;;
    set|cycle)      theme_cmd_pending "$command" ;;
    help|--help|-h) theme_cmd_help ;;
    *)
      log_error "Unknown theme command: $command"
      echo ""
      theme_cmd_help
      exit 1
      ;;
  esac
}

main "$@"
