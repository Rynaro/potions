#!/bin/bash

# .potions/lib/help.sh — Potions Help Popup: rendering engine + content registry
#
# Sourcing guard: function-presence check mirrors accessories.sh pattern.
# Prevents double-definition when sourced multiple times across processes.
if [ -n "$POTIONS_HELP_SOURCED" ] && type detect_terminal_capabilities &>/dev/null; then
  return 0
fi
POTIONS_HELP_SOURCED=1

# ── Capability Detection ──────────────────────────────────────────────────────

detect_terminal_capabilities() {
  # Color: requires a TTY on stdout AND NO_COLOR unset
  if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
    POTIONS_HAS_COLOR=true
  else
    POTIONS_HAS_COLOR=false
  fi

  # Unicode: test if the UTF-8 box-drawing char '─' produces 3 bytes (multi-byte path)
  local _bytes
  _bytes=$(printf '%s' '─' 2>/dev/null | wc -c | tr -d ' ') || _bytes=1
  if [ "${_bytes:-1}" -ge 3 ] 2>/dev/null; then
    POTIONS_HAS_UNICODE=true
  else
    POTIONS_HAS_UNICODE=false
  fi

  # Display width: tput -> $COLUMNS -> 72 fallback; clamp to [72, 100]
  local _w
  _w=$(tput cols 2>/dev/null) || _w=""
  if [ -z "$_w" ] || ! echo "$_w" | grep -qE '^[0-9]+$' 2>/dev/null; then
    _w="${COLUMNS:-0}"
  fi
  _w=$(echo "$_w" | grep -oE '^[0-9]+' || echo "0")
  if [ "${_w:-0}" -lt 72 ]; then
    _w=72
  elif [ "${_w:-0}" -gt 100 ]; then
    _w=100
  fi
  POTIONS_DISPLAY_WIDTH="$_w"
  _potions_apply_palette
}

# Read one CTERM token. .theme files are data, never sourced.
_potions_theme_cterm() {
  local file="$1"
  local key="$2"
  local line val

  [ -f "$file" ] || return 1
  line=$(grep -E "^${key}=[0-9]{1,3}$" "$file" 2>/dev/null | head -1) || true
  val="${line#*=}"
  case "$val" in
    ''|*[!0-9]*) return 1 ;;
  esac
  if [ "$val" -gt 255 ]; then
    return 1
  fi
  printf '%s' "$val"
}

# Point the help/door chrome at the active variant.
# Light paper (white, sepia) cannot use ANSI 37: that slot is the paper.
# 256-color tokens stay put when the terminal remaps the 16 ANSI colors.
_potions_apply_palette() {
  local home state theme variant root themes varfile basefile base
  local primary cool warm ink muted

  [ "${POTIONS_HAS_COLOR:-false}" = true ] || return 0

  home="${POTIONS_HOME:-$HOME/.potions}"
  state=""
  if [ -f "$home/config/theme.conf" ]; then
    state=$(head -1 "$home/config/theme.conf" 2>/dev/null | tr -d '[:space:]')
  fi

  case "$state" in
    "")
      theme="alchemists-orchid"
      variant="dark"
      ;;
    *:*)
      theme="${state%%:*}"
      variant="${state#*:}"
      ;;
    *)
      theme="$state"
      variant="dark"
      ;;
  esac

  case "$theme" in
    ""|*[!A-Za-z0-9._-]*) return 0 ;;
  esac
  case "$variant" in
    ""|*[!A-Za-z0-9._-]*) return 0 ;;
  esac

  themes=""
  for root in "$home/themes" "$(cd "$(dirname "${BASH_SOURCE[0]}")/../themes" 2>/dev/null && pwd)"; do
    [ -n "$root" ] || continue
    if [ -f "$root/$theme/$variant.theme" ]; then
      themes="$root/$theme"
      break
    fi
  done
  [ -n "$themes" ] || return 0

  varfile="$themes/$variant.theme"
  basefile=""
  base=$(grep -E '^META_BASE=[A-Za-z0-9._-]+$' "$varfile" 2>/dev/null | head -1) || true
  base="${base#META_BASE=}"
  if [ -n "$base" ] && [ -f "$themes/$base.theme" ]; then
    basefile="$themes/$base.theme"
  fi

  _potions_pick_cterm() {
    local key="$1"
    local val=""
    val=$(_potions_theme_cterm "$varfile" "$key" || true)
    if [ -z "$val" ] && [ -n "$basefile" ]; then
      val=$(_potions_theme_cterm "$basefile" "$key" || true)
    fi
    printf '%s' "$val"
  }

  primary=$(_potions_pick_cterm COLOR_PRIMARY_CTERM)
  cool=$(_potions_pick_cterm COLOR_ACCENT_COOL_CTERM)
  warm=$(_potions_pick_cterm COLOR_ACCENT_WARM_CTERM)
  ink=$(_potions_pick_cterm COLOR_ON_SURFACE_CTERM)
  POTIONS_CTERM_PRIMARY="$primary"
  POTIONS_CTERM_SURFACE=$(_potions_pick_cterm COLOR_SURFACE_CTERM)
  case "$variant" in
    white|sepia)
      muted=$(_potions_pick_cterm COLOR_MUTED_CTERM)
      POTIONS_CTERM_SELECT_FG="$ink"
      ;;
    *)
      muted=$(_potions_pick_cterm COLOR_SECONDARY_CTERM)
      POTIONS_CTERM_SELECT_FG="$POTIONS_CTERM_SURFACE"
      ;;
  esac

  # Keys use the warm accent when it is a deep ink (light variants).
  # On dark, the same token is a pale gold and stays readable.
  [ -n "$primary" ] && POTIONS_COLOR_BRAND=$(printf '\033[1;38;5;%sm' "$primary")
  [ -n "$cool" ] && POTIONS_COLOR_DIM=$(printf '\033[38;5;%sm' "$cool")
  [ -n "$warm" ] && POTIONS_COLOR_KEY=$(printf '\033[1;38;5;%sm' "$warm")
  [ -n "$warm" ] && POTIONS_COLOR_WARM=$(printf '\033[38;5;%sm' "$warm")
  [ -n "$ink" ] && POTIONS_COLOR_VALUE=$(printf '\033[38;5;%sm' "$ink")
  [ -n "$muted" ] && POTIONS_COLOR_MUTED=$(printf '\033[38;5;%sm' "$muted")
}

# ── Brand Constants ───────────────────────────────────────────────────────────
# Approximations of the Zellij 'potions' theme palette as ANSI escape codes.

POTIONS_COLOR_BRAND='\033[0;35m'   # magenta  — identity / brand borders
POTIONS_COLOR_DIM='\033[0;36m'     # cyan     — secondary text, tagline
POTIONS_COLOR_KEY='\033[1;33m'     # yellow   — key names
POTIONS_COLOR_WARM='\033[33m'      # yellow   — the bottle, unbolded
POTIONS_COLOR_VALUE='\033[1;37m'   # white    — descriptions / titles
POTIONS_COLOR_MUTED='\033[2;37m'   # dim      — notes, hints, footer
POTIONS_NC='\033[0m'               # reset

# ── Internal Helpers ──────────────────────────────────────────────────────────

# Repeat char $1 exactly $2 times (Bash 3 compatible — no printf %*s reliance)
_potions_repeat() {
  local char="$1"
  local count="$2"
  local i=0
  local out=""
  while [ "$i" -lt "$count" ]; do
    out="${out}${char}"
    i=$((i + 1))
  done
  printf '%s' "$out"
}

# Hard-cut $1 to at most $2 characters. Same expansion the door uses for details.
_potions_cut() {
  local text="$1"
  local max="${2:-0}"
  if [ "$max" -lt 0 ]; then
    max=0
  fi
  if [ "${#text}" -gt "$max" ]; then
    printf '%s' "${text:0:max}"
  else
    printf '%s' "$text"
  fi
}

# Faint (SGR 2) disappears in several terminals. A hint is a sentence.
# Prints nothing when muted carries the SGR 2 parameter; otherwise prints it.
_potions_quiet_color() {
  case "${POTIONS_COLOR_MUTED:-}" in
    *$'\033[2;'*|*'[2;'*) printf '' ;;
    *) printf '%s' "${POTIONS_COLOR_MUTED:-}" ;;
  esac
}

# ── Renderer ──────────────────────────────────────────────────────────────────

render_popup_header() {
  local version="${1:-}"
  local width="${POTIONS_DISPLAY_WIDTH:-72}"
  local inner=$((width - 2))

  if [ "$inner" -lt 0 ]; then
    inner=0
  fi

  local H TL TR BL BR V
  if [ "${TERM:-}" = "linux" ] || [ "$POTIONS_HAS_UNICODE" != true ]; then
    H="-"; TL="+"; TR="+"; BL="+"; BR="+"; V="|"
  else
    H="─"; TL="╭"; TR="╮"; BL="╰"; BR="╯"; V="│"
  fi

  local hrule; hrule=$(_potions_repeat "$H" "$inner")

  # Title line: "potions" centered (all ASCII — safe for ${#} on Bash 3)
  local title="potions"
  title=$(_potions_cut "$title" "$inner")
  local pad_total=$((inner - ${#title}))
  if [ "$pad_total" -lt 0 ]; then
    pad_total=0
  fi
  local pad_left=$((pad_total / 2))
  local pad_right=$((pad_total - pad_left))
  local pl; pl=$(_potions_repeat " " "$pad_left")
  local pr; pr=$(_potions_repeat " " "$pad_right")

  # Subtitle line: all ASCII; tilde used as separator (safe for ${#})
  local subtitle="your cozy dev environment"
  if [ -n "$version" ]; then
    subtitle="your cozy dev environment  ~  v${version}"
  fi
  subtitle=$(_potions_cut "$subtitle" "$inner")
  local sub_total=$((inner - ${#subtitle}))
  if [ "$sub_total" -lt 0 ]; then
    sub_total=0
  fi
  local sub_left=$((sub_total / 2))
  local sub_right=$((sub_total - sub_left))
  local sl; sl=$(_potions_repeat " " "$sub_left")
  local sr; sr=$(_potions_repeat " " "$sub_right")

  echo ""
  if [ "$POTIONS_HAS_COLOR" = true ]; then
    printf "${POTIONS_COLOR_BRAND}%s%s%s${POTIONS_NC}\n"                                                                       "$TL" "$hrule"    "$TR"
    printf "${POTIONS_COLOR_BRAND}%s${POTIONS_NC}%s${POTIONS_COLOR_KEY}%s${POTIONS_NC}%s${POTIONS_COLOR_BRAND}%s${POTIONS_NC}\n" "$V"  "$pl" "$title" "$pr" "$V"
    printf "${POTIONS_COLOR_BRAND}%s${POTIONS_NC}%s${POTIONS_COLOR_DIM}%s${POTIONS_NC}%s${POTIONS_COLOR_BRAND}%s${POTIONS_NC}\n"  "$V"  "$sl" "$subtitle" "$sr" "$V"
    printf "${POTIONS_COLOR_BRAND}%s%s%s${POTIONS_NC}\n"                                                                       "$BL" "$hrule"    "$BR"
  else
    printf "%s%s%s\n"   "$TL" "$hrule" "$TR"
    printf "%s%s%s%s%s\n" "$V" "$pl" "$title" "$pr" "$V"
    printf "%s%s%s%s%s\n" "$V" "$sl" "$subtitle" "$sr" "$V"
    printf "%s%s%s\n"   "$BL" "$hrule" "$BR"
  fi
}

render_section_header() {
  local title="$1"
  local width="${POTIONS_DISPLAY_WIDTH:-72}"

  local H
  if [ "${TERM:-}" = "linux" ] || [ "$POTIONS_HAS_UNICODE" != true ]; then
    H="-"
  else
    H="─"
  fi

  # Layout: "  HH title HHH..." (title is caller-provided ASCII)
  # Display width of prefix: 2 spaces + 2xH + 1 space + title + 1 space = ${#title} + 6
  local prefix_len=$((${#title} + 6))
  local remaining=$((width - prefix_len))
  if [ "$remaining" -lt 1 ]; then remaining=1; fi
  local suffix; suffix=$(_potions_repeat "$H" "$remaining")

  echo ""
  if [ "$POTIONS_HAS_COLOR" = true ]; then
    printf "${POTIONS_COLOR_BRAND}  %s%s ${POTIONS_COLOR_VALUE}%s${POTIONS_COLOR_BRAND} %s${POTIONS_NC}\n" "$H" "$H" "$title" "$suffix"
  else
    printf "  %s%s %s %s\n" "$H" "$H" "$title" "$suffix"
  fi
  echo ""
}

render_keybind_row() {
  local key="$1"
  local desc="$2"
  local key_col=18    # fixed display width for the key column
  local width="${POTIONS_DISPLAY_WIDTH:-72}"
  local desc_width

  if [ "${#key}" -gt "$key_col" ]; then
    key="${key:0:key_col}"
  fi
  desc_width=$((width - 4 - key_col - 2))
  if [ "$desc_width" -lt 0 ]; then
    desc_width=0
  fi
  desc=$(_potions_cut "$desc" "$desc_width")

  if [ "$POTIONS_HAS_COLOR" = true ]; then
    printf "    ${POTIONS_COLOR_KEY}%-${key_col}s${POTIONS_NC}  ${POTIONS_COLOR_VALUE}%s${POTIONS_NC}\n" "$key" "$desc"
  else
    printf "    %-${key_col}s  %s\n" "$key" "$desc"
  fi
}

render_note_row() {
  local note="$1"
  local width="${POTIONS_DISPLAY_WIDTH:-72}"
  local prefix="    # "
  local body_width line quiet

  body_width=$((width - ${#prefix}))
  if [ "$body_width" -lt 0 ]; then
    body_width=0
  fi
  note=$(_potions_cut "$note" "$body_width")
  line="${prefix}${note}"
  line=$(_potions_cut "$line" "$width")

  quiet=$(_potions_quiet_color)
  if [ "$POTIONS_HAS_COLOR" = true ] && [ -n "$quiet" ]; then
    printf "${quiet}%s${POTIONS_NC}\n" "$line"
  else
    printf "%s\n" "$line"
  fi
}

render_popup_footer() {
  local width="${POTIONS_DISPLAY_WIDTH:-72}"
  local inner=$((width - 2))
  local quiet hint line

  if [ "$inner" -lt 0 ]; then
    inner=0
  fi

  local H BL BR
  if [ "${TERM:-}" = "linux" ] || [ "$POTIONS_HAS_UNICODE" != true ]; then
    H="-"; BL="+"; BR="+"
  else
    H="─"; BL="╰"; BR="╯"
  fi

  local hrule; hrule=$(_potions_repeat "$H" "$inner")
  hint="Customize: ~/.potions/zellij/user.kdl | ~/.potions/config/aliases.zsh"
  line="  ${hint}"
  line=$(_potions_cut "$line" "$width")

  echo ""
  if [ "$POTIONS_HAS_COLOR" = true ]; then
    printf "${POTIONS_COLOR_BRAND}%s%s%s${POTIONS_NC}\n" "$BL" "$hrule" "$BR"
    quiet=$(_potions_quiet_color)
    if [ -n "$quiet" ]; then
      printf "${quiet}%s${POTIONS_NC}\n" "$line"
    else
      printf "%s\n" "$line"
    fi
  else
    printf "%s%s%s\n" "$BL" "$hrule" "$BR"
    printf "%s\n" "$line"
  fi
  echo ""
}

# ── Content Registry ──────────────────────────────────────────────────────────
# Ordered indexed array (Bash 3 compatible — no associative arrays).
# To add a section: append its name here and define help_section_<name>() below.

POTIONS_HELP_SECTIONS=("zellij" "zsh" "neovim")

# ── Section: Zellij ───────────────────────────────────────────────────────────

help_section_zellij() {
  render_section_header "Zellij - Multiplexer"

  render_note_row "The Ctrl+a prefix works on every platform. Prefer it."
  render_keybind_row "Ctrl+a"           "Enter prefix mode (tmux style)"
  render_keybind_row "F1  /  Ctrl+a ?"  "Open the floating cheatsheet (universal)"
  render_keybind_row "Ctrl+a  g"        "Open the Potions door"
  echo ""

  render_keybind_row "Ctrl+a  |"        "Split pane right"
  render_keybind_row "Ctrl+a  -"        "Split pane down"
  render_keybind_row "Ctrl+a  c"        "New tab"
  render_keybind_row "Ctrl+a  x"        "Close pane"
  render_keybind_row "Ctrl+a  X"        "Close tab"
  render_keybind_row "Ctrl+a  n / p"    "Next / previous tab"
  render_keybind_row "Ctrl+a  h/j/k/l"  "Navigate panes"
  render_keybind_row "Ctrl+a  r"        "Resize mode (then hjkl)"
  render_keybind_row "Ctrl+a  z"        "Toggle fullscreen"
  render_keybind_row "Ctrl+a  S"        "Session manager"
  echo ""

  render_keybind_row "Alt+h/j/k/l"      "Navigate panes (no prefix)"
  render_keybind_row "Alt+d"            "Split pane right"
  render_keybind_row "Alt+t"            "New tab"
  render_keybind_row "Alt+w"            "Close pane"
  render_keybind_row "Alt+n / Alt+p"    "Next / previous tab"
  render_keybind_row "Alt+Enter"        "Toggle fullscreen"
  render_note_row "Alt is Option. It needs Option as Meta, or use Ctrl+a."
  render_note_row "Terminal.app does not forward Ctrl+Tab. Use Alt+n or Alt+p."
}

# ── Section: Zsh ──────────────────────────────────────────────────────────────

help_section_zsh() {
  render_section_header "Zsh - Shell"

  render_keybind_row "Ctrl+a"    "Beginning of line"
  render_keybind_row "Ctrl+e"    "End of line"
  render_keybind_row "Ctrl+u"    "Clear line to start"
  render_keybind_row "Ctrl+k"    "Clear line to end"
  render_keybind_row "Ctrl+w"    "Delete word backward"
  render_keybind_row "Ctrl+l"    "Clear screen"
  render_note_row "Ctrl+a also enters Zellij prefix mode when running inside Zellij"
  echo ""

  render_keybind_row "Ctrl+r"    "Reverse history search"
  render_keybind_row "Ctrl+p"    "Previous history entry"
  render_keybind_row "Ctrl+n"    "Next history entry"
  render_keybind_row "Ctrl+c"    "Interrupt (SIGINT)"
  render_keybind_row "Ctrl+d"    "EOF / logout"
}

# ── Section: Neovim ───────────────────────────────────────────────────────────

help_section_neovim() {
  render_section_header "Neovim - Editor"

  render_keybind_row "Ctrl+s"     "Save file"
  render_keybind_row "Ctrl+n"     "Toggle NERDTree"
  render_keybind_row "Ctrl+c"     "Copy to clipboard (visual)"
  render_keybind_row "Ctrl+v"     "Paste from clipboard"
  echo ""

  render_keybind_row "Space ff"   "Find files (Telescope)"
  render_keybind_row "Space fg"   "Live grep"
  render_keybind_row "Space fb"   "Open buffers"
  render_keybind_row "Space q"    "Quit"
  render_keybind_row "Space wq"   "Write and quit"
  render_keybind_row "Space w"    "Write (save)"
  render_keybind_row "Space h/l"  "Previous / next buffer"
  render_keybind_row "Space nf"   "NERDTree: reveal file"
  render_keybind_row "Space /"    "Search word under cursor"
  render_keybind_row "Space j/k"  "Move line(s) down / up"
  render_keybind_row "Space d"    "Multi-cursor: add on word"
  render_note_row "Standard Vim motions (gg, G, w, b, Ctrl+u/d) are unchanged"
  render_note_row "Full reference: ~/.potions/KEYMAPS.md"
}

# ── Section: Commands ─────────────────────────────────────────────────────────

help_section_commands() {
  render_section_header "Commands"

  render_keybind_row "upgrade"      "Upgrade Potions to latest version"
  render_keybind_row "update"       "Check if updates are available"
  render_keybind_row "keybindings"  "Show keybindings popup (aliases: keys, kb)"
  render_keybind_row "door"         "Open the front door (resume, begin, notes)"
  render_keybind_row "version"      "Show current version"
  render_keybind_row "status"       "Show installation status"
  render_keybind_row "info"         "Show system information"
  render_keybind_row "doctor"       "Run health check"
  render_keybind_row "theme"        "Switch/cycle the colorscheme (set, cycle, list)"
  render_keybind_row "terminal"     "Configure terminals (Ghostty/Termux): setup, status, reload"
  render_keybind_row "reload"       "Regenerate artifacts and push live (all|terminal|shell|nvim|zellij)"
  render_keybind_row "plugin"       "Plugin management (install, list, ...)"
  render_keybind_row "help"         "Show this help"
}
