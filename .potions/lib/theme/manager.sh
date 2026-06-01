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
    current                 Show the active theme and variant
    list                    List installed themes and their variants
    set <theme> [variant]   Switch theme/variant and regenerate all targets
    cycle                   Cycle to the next variant of the active theme
    verify <dir>            Validate a bring-your-own theme directory
    install <dir>           Verify and install a bring-your-own theme
    uninstall <id>          Remove an installed bring-your-own theme
    help                    Show this message
EOF
}

# Is <variant> available for the theme at <theme_dir>?
theme_variant_valid() {
  [ -f "$1/$2.theme" ]
}

# Repaint the running terminal live via OSC (best-effort; no-op inside Zellij).
theme_apply_osc() {
  local home ansi
  home="${POTIONS_HOME:-$HOME/.potions}"
  ansi="$home/config/generated/ansi-map.sh"
  if [ -f "$ansi" ]; then
    # shellcheck source=/dev/null
    . "$ansi" 2>/dev/null || return 0
    command -v potions_apply_terminal_palette > /dev/null 2>&1 && potions_apply_terminal_palette
  fi
}

# Print which surfaces are live now vs need a restart for the current env.
theme_print_reload_matrix() {
  echo ""
  log_info "Applied. Surface status:"
  if [ -n "${ZELLIJ:-}" ]; then
    echo "  - Zellij     persisted; reload config or start a new session to see it"
    echo "  - Terminal   owned by Zellij in-session (palette set by the Zellij theme)"
  else
    echo "  - Terminal   repainted live via OSC (if your terminal supports it)"
    echo "  - Zellij     persisted; applies on next Zellij start"
  fi
  echo "  - NeoVim     persisted; :source \$MYVIMRC or restart nvim to see it"
  echo "  - Alacritty  persisted; reopen/reload the terminal to import it"
}

# Resolve + regenerate all artifacts for <theme> <variant>.
# mode: "switch" (write state + osc + matrix) or "quiet" (regenerate only).
theme_apply() {
  local theme="$1" variant="$2" mode="${3:-switch}" theme_dir

  theme_dir="$(theme_registry_find "$theme" 2>/dev/null || true)"
  if [ -z "$theme_dir" ]; then
    log_error "Theme not found: $theme"
    log_info "Run 'potions theme list' to see installed themes."
    return 1
  fi
  if ! theme_variant_valid "$theme_dir" "$variant"; then
    log_error "Variant '$variant' not available for theme '$theme'."
    return 1
  fi

  if ! theme_generate "$theme_dir" "$variant"; then
    log_error "Theme generation failed; state unchanged."
    return 1
  fi

  if [ "$mode" = "switch" ]; then
    theme_state_write "$theme" "$variant"
    theme_apply_osc
    log_success "Theme set to: $(theme_registry_name "$theme") ($variant)"
    theme_print_reload_matrix
  fi
  return 0
}

theme_cmd_set() {
  local theme="$1" variant="$2" theme_dir
  if [ -z "$theme" ]; then
    log_error "Usage: potions theme set <theme> [variant]"
    return 1
  fi
  theme_dir="$(theme_registry_find "$theme" 2>/dev/null || true)"
  if [ -z "$theme_dir" ]; then
    log_error "Theme not found: $theme"
    log_info "Run 'potions theme list' to see installed themes."
    return 1
  fi
  if [ -z "$variant" ]; then
    # Default to the first declared variant, else 'dark'
    variant="$(theme_registry_field "$theme_dir/manifest" META_VARIANTS 2>/dev/null | cut -d, -f1)"
    [ -n "$variant" ] || variant="dark"
  fi
  theme_apply "$theme" "$variant" switch
}

theme_cmd_cycle() {
  local theme variant variants next first found
  theme="$(theme_state_theme)"
  variant="$(theme_state_variant)"
  local theme_dir
  theme_dir="$(theme_registry_find "$theme" 2>/dev/null || true)"
  if [ -z "$theme_dir" ]; then
    log_error "Active theme '$theme' not found."
    return 1
  fi
  variants="$(theme_registry_field "$theme_dir/manifest" META_VARIANTS 2>/dev/null | tr ',' ' ')"
  [ -n "$variants" ] || variants="dark"

  first=""
  next=""
  found=false
  local v
  for v in $variants; do
    [ -n "$first" ] || first="$v"
    if [ "$found" = true ]; then
      next="$v"
      break
    fi
    [ "$v" = "$variant" ] && found=true
  done
  [ -n "$next" ] || next="$first"  # wrap around

  theme_apply "$theme" "$next" switch
}

# Internal: regenerate artifacts for the active theme (used by install/upgrade).
theme_cmd_regen() {
  local theme variant
  theme="$(theme_state_theme)"
  variant="$(theme_state_variant)"
  theme_apply "$theme" "$variant" quiet
}

# Verify a bring-your-own theme directory without installing it.
theme_cmd_verify() {
  local dir="$1"
  if [ -z "$dir" ]; then
    log_error "Usage: potions theme verify <theme-dir>"
    return 1
  fi
  if theme_verify_dir "$dir"; then
    log_success "Theme at '$dir' is valid and safe to install."
    return 0
  fi
  log_error "Theme at '$dir' failed verification."
  return 1
}

# Install a verified bring-your-own theme into the user themes dir.
# Only the manifest and *.theme files are copied; ids are sanitized.
theme_cmd_install() {
  local src="$1" id user_dir dest
  if [ -z "$src" ]; then
    log_error "Usage: potions theme install <theme-dir>"
    return 1
  fi
  if ! theme_verify_dir "$src"; then
    log_error "Theme failed verification; not installed."
    return 1
  fi

  id="$(theme_registry_field "$src/manifest" META_ID 2>/dev/null || true)"
  [ -n "$id" ] || id="$(basename "$src")"
  case "$id" in
    *[!A-Za-z0-9_-]* | "")
      log_error "Invalid theme id '$id' (allowed: A-Z a-z 0-9 _ -)."
      return 1
      ;;
  esac

  user_dir="$(theme_registry_user_dir)"
  dest="$user_dir/$id"
  if [ -d "$dest" ]; then
    log_warning "Overwriting existing BYO theme '$id'."
  fi
  mkdir -p "$dest"
  cp "$src/manifest" "$dest/manifest"
  cp "$src"/*.theme "$dest/" 2> /dev/null || true

  log_success "Installed BYO theme '$id' (trust: byo)."
  log_info "Activate with: potions theme set $id"
}

# Remove a bring-your-own theme. Built-in themes cannot be uninstalled.
theme_cmd_uninstall() {
  local id="$1" dir
  if [ -z "$id" ]; then
    log_error "Usage: potions theme uninstall <id>"
    return 1
  fi
  case "$id" in
    *[!A-Za-z0-9_-]* | "")
      log_error "Invalid theme id '$id'."
      return 1
      ;;
  esac
  dir="$(theme_registry_user_dir)/$id"
  if [ ! -d "$dir" ]; then
    log_error "BYO theme '$id' not found (built-in themes cannot be uninstalled)."
    return 1
  fi
  rm -rf "$dir"
  log_success "Uninstalled BYO theme '$id'."
}

main() {
  local command="${1:-current}"
  shift || true
  case "$command" in
    current)        theme_cmd_current ;;
    list|ls)        theme_cmd_list ;;
    set)            theme_cmd_set "$@" ;;
    cycle)          theme_cmd_cycle ;;
    regen)          theme_cmd_regen ;;
    verify)         theme_cmd_verify "$@" ;;
    install)        theme_cmd_install "$@" ;;
    uninstall)      theme_cmd_uninstall "$@" ;;
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
