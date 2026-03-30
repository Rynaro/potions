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
}

# ── Brand Constants ───────────────────────────────────────────────────────────
# Approximations of the Zellij 'potions' theme palette as ANSI escape codes.

POTIONS_COLOR_BRAND='\033[0;35m'   # magenta  — identity / brand borders
POTIONS_COLOR_DIM='\033[0;36m'     # cyan     — secondary text, section rules
POTIONS_COLOR_KEY='\033[1;33m'     # yellow   — key names
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

# ── Renderer ──────────────────────────────────────────────────────────────────

render_popup_header() {
  local version="${1:-}"
  local width="${POTIONS_DISPLAY_WIDTH:-72}"
  local inner=$((width - 2))

  local H TL TR BL BR V
  if [ "$POTIONS_HAS_UNICODE" = true ]; then
    H="─"; TL="╭"; TR="╮"; BL="╰"; BR="╯"; V="│"
  else
    H="-"; TL="+"; TR="+"; BL="+"; BR="+"; V="|"
  fi

  local hrule; hrule=$(_potions_repeat "$H" "$inner")

  # Title line: "potions" centered (all ASCII — safe for ${#} on Bash 3)
  local title="potions"
  local pad_total=$((inner - ${#title}))
  local pad_left=$((pad_total / 2))
  local pad_right=$((pad_total - pad_left))
  local pl; pl=$(_potions_repeat " " "$pad_left")
  local pr; pr=$(_potions_repeat " " "$pad_right")

  # Subtitle line: all ASCII; tilde used as separator (safe for ${#})
  local subtitle="your cozy dev environment"
  if [ -n "$version" ]; then
    subtitle="your cozy dev environment  ~  v${version}"
  fi
  local sub_total=$((inner - ${#subtitle}))
  local sub_left=$((sub_total / 2))
  local sub_right=$((sub_total - sub_left))
  local sl; sl=$(_potions_repeat " " "$sub_left")
  local sr; sr=$(_potions_repeat " " "$sub_right")

  echo ""
  if [ "$POTIONS_HAS_COLOR" = true ]; then
    printf "${POTIONS_COLOR_BRAND}%s%s%s${POTIONS_NC}\n"                                                                         "$TL" "$hrule"    "$TR"
    printf "${POTIONS_COLOR_BRAND}%s${POTIONS_NC}%s${POTIONS_COLOR_VALUE}%s${POTIONS_NC}%s${POTIONS_COLOR_BRAND}%s${POTIONS_NC}\n" "$V"  "$pl" "$title" "$pr" "$V"
    printf "${POTIONS_COLOR_BRAND}%s${POTIONS_NC}%s${POTIONS_COLOR_DIM}%s${POTIONS_NC}%s${POTIONS_COLOR_BRAND}%s${POTIONS_NC}\n"  "$V"  "$sl" "$subtitle" "$sr" "$V"
    printf "${POTIONS_COLOR_BRAND}%s%s%s${POTIONS_NC}\n"                                                                         "$BL" "$hrule"    "$BR"
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
  if [ "$POTIONS_HAS_UNICODE" = true ]; then
    H="─"
  else
    H="-"
  fi

  # Layout: "  -- title -------..." (title is caller-provided ASCII)
  # Display width of prefix: 2 spaces + 2xH + 1 space + title + 1 space = ${#title} + 6
  local prefix_len=$((${#title} + 6))
  local remaining=$((width - prefix_len))
  if [ "$remaining" -lt 1 ]; then remaining=1; fi
  local suffix; suffix=$(_potions_repeat "$H" "$remaining")

  echo ""
  if [ "$POTIONS_HAS_COLOR" = true ]; then
    printf "${POTIONS_COLOR_DIM}  %s%s ${POTIONS_COLOR_VALUE}%s${POTIONS_COLOR_DIM} %s${POTIONS_NC}\n" "$H" "$H" "$title" "$suffix"
  else
    printf "  -- %s %s\n" "$title" "$suffix"
  fi
  echo ""
}

render_keybind_row() {
  local key="$1"
  local desc="$2"
  local key_col=18    # fixed display width for the key column

  if [ "$POTIONS_HAS_COLOR" = true ]; then
    printf "    ${POTIONS_COLOR_KEY}%-${key_col}s${POTIONS_NC}  ${POTIONS_COLOR_VALUE}%s${POTIONS_NC}\n" "$key" "$desc"
  else
    printf "    %-${key_col}s  %s\n" "$key" "$desc"
  fi
}

render_note_row() {
  local note="$1"
  if [ "$POTIONS_HAS_COLOR" = true ]; then
    printf "    ${POTIONS_COLOR_MUTED}# %s${POTIONS_NC}\n" "$note"
  else
    printf "    # %s\n" "$note"
  fi
}

render_popup_footer() {
  local width="${POTIONS_DISPLAY_WIDTH:-72}"
  local inner=$((width - 2))

  local H BL BR
  if [ "$POTIONS_HAS_UNICODE" = true ]; then
    H="─"; BL="╰"; BR="╯"
  else
    H="-"; BL="+"; BR="+"
  fi

  local hrule; hrule=$(_potions_repeat "$H" "$inner")
  local hint="Customize: ~/.potions/zellij/user.kdl  |  ~/.potions/config/aliases.zsh"

  echo ""
  if [ "$POTIONS_HAS_COLOR" = true ]; then
    printf "${POTIONS_COLOR_BRAND}%s%s%s${POTIONS_NC}\n" "$BL" "$hrule" "$BR"
    printf "${POTIONS_COLOR_MUTED}  %s${POTIONS_NC}\n" "$hint"
  else
    printf "%s%s%s\n" "$BL" "$hrule" "$BR"
    printf "  %s\n" "$hint"
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

  render_keybind_row "Ctrl+a"           "Enter prefix mode (tmux style)"
  echo ""

  render_keybind_row "Alt+h/j/k/l"      "Navigate panes"
  render_keybind_row "Alt+d"            "Split pane right"
  render_keybind_row "Alt+t"            "New tab"
  render_keybind_row "Alt+w"            "Close pane"
  render_keybind_row "Alt+n"            "Next tab"
  render_keybind_row "Alt+p"            "Previous tab"
  render_keybind_row "Alt+Enter"        "Toggle fullscreen"
  render_keybind_row "Ctrl+Tab"         "Next tab"
  render_keybind_row "Ctrl+Shift+Tab"   "Previous tab"
  render_note_row "macOS: Ctrl+Tab not forwarded by Terminal.app -- use Alt+n / Alt+p"
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
  render_keybind_row "version"      "Show current version"
  render_keybind_row "status"       "Show installation status"
  render_keybind_row "info"         "Show system information"
  render_keybind_row "doctor"       "Run health check"
  render_keybind_row "plugin"       "Plugin management (install, list, ...)"
  render_keybind_row "help"         "Show this help"
}
