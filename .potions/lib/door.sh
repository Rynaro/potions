#!/bin/bash

# .potions/lib/door.sh — Potions front door
#
# The personal shell lands here instead of attaching a random Zellij session.
# Resume rejoins the living mood. Begin is the only path that mints a name.
# Quit returns to the shell. Drawing goes through lib/help.sh.

if [ -n "${POTIONS_DOOR_SOURCED:-}" ] && type potions_door_main >/dev/null 2>&1; then
  return 0 2>/dev/null || exit 0
fi
POTIONS_DOOR_SOURCED=1

if ! type render_popup_header >/dev/null 2>&1; then
  # shellcheck source=/dev/null
  . "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/help.sh"
fi

# Session names we will pass to Zellij. Alchemical names fit; POTIONS_SESSION
# may be a short user pin. Reject anything that could be read as a flag.
potions_door_valid_session_name() {
  local name="$1"
  case "$name" in
    ""|-*|*[!A-Za-z0-9._-]*) return 1 ;;
  esac
  if [ "${#name}" -gt 64 ]; then
    return 1
  fi
  return 0
}

# Valid POTIONS_SESSION, or failure when it is unset or unsafe.
potions_door_pinned_name() {
  local name="${POTIONS_SESSION:-}"
  potions_door_valid_session_name "$name" || return 1
  printf '%s' "$name"
}

potions_door_strip_ansi() {
  printf '%s' "$1" | sed "s/$(printf '\033')\\[[0-9;]*[[:alpha:]]//g"
}

# zshrc that ships beside this library (repo checkout or ~/.potions).
potions_door_zshrc_path() {
  if [ -n "${POTIONS_DOOR_ZSHRC:-}" ] && [ -f "$POTIONS_DOOR_ZSHRC" ]; then
    printf '%s' "$POTIONS_DOOR_ZSHRC"
    return 0
  fi
  local dir
  dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  if [ -f "$dir/.zshrc" ]; then
    printf '%s' "$dir/.zshrc"
    return 0
  fi
  if [ -n "${POTIONS_HOME:-}" ] && [ -f "$POTIONS_HOME/.zshrc" ]; then
    printf '%s' "$POTIONS_HOME/.zshrc"
    return 0
  fi
  return 1
}

# Allowlisted zsh entry points. The function name is never taken from the user.
potions_door_zsh_call() {
  local fn="$1"
  local arg="${2:-}"
  local zshrc
  case "$fn" in
    _potions_begin_mood|_potions_resume_mood|_potions_zellij_session_name) ;;
    *) return 1 ;;
  esac
  zshrc=$(potions_door_zshrc_path) || return 1
  zsh -c 'source "$1" >/dev/null 2>&1 || exit 1; "$2" "$3"' _ "$zshrc" "$fn" "$arg"
}

potions_door_mint_name() {
  local name
  name=$(potions_door_zsh_call _potions_zellij_session_name "") || return 1
  potions_door_valid_session_name "$name" || return 1
  printf '%s' "$name"
}

potions_door_read_session_list() {
  if [ -n "${POTIONS_DOOR_LIST_FIXTURE:-}" ] && [ -f "$POTIONS_DOOR_LIST_FIXTURE" ]; then
    cat "$POTIONS_DOOR_LIST_FIXTURE"
    return 0
  fi
  local config_dir="${POTIONS_HOME:-$HOME/.potions}/zellij"
  zellij --config-dir "$config_dir" list-sessions --no-formatting 2>/dev/null || true
  return 0
}

# stdin: `zellij list-sessions --no-formatting` text (ANSI tolerated).
# stdout: the one living mood, or nothing.
# POTIONS_SESSION pins Resume to that name, and only when it is actually alive.
# Does not mint.
potions_door_select_living() {
  local line name living="" current="" pinned="" pin_alive=0
  pinned=""
  if pinned=$(potions_door_pinned_name); then
    :
  else
    pinned=""
  fi

  while IFS= read -r line || [ -n "$line" ]; do
    [ -n "$line" ] || continue
    line=$(potions_door_strip_ansi "$line")
    case "$line" in
      *"[Created "*) ;;
      *) continue ;;
    esac
    name="${line%% *}"
    potions_door_valid_session_name "$name" || continue
    # The lobby that holds the modal when no mood exists. Not a mood.
    if [ "$name" = "potions" ]; then
      continue
    fi
    case "$line" in
      *EXITED*) continue ;;
    esac
    living="$name"
    case "$line" in
      *"(current)"*) current="$name" ;;
    esac
    if [ -n "$pinned" ] && [ "$name" = "$pinned" ]; then
      pin_alive=1
    fi
  done

  if [ -n "$pinned" ]; then
    if [ "$pin_alive" -eq 1 ]; then
      printf '%s' "$pinned"
    fi
    return 0
  fi
  if [ -n "$current" ]; then
    printf '%s' "$current"
    return 0
  fi
  if [ -n "$living" ]; then
    printf '%s' "$living"
  fi
  return 0
}

potions_door_living_name() {
  local list living
  list=$(potions_door_read_session_list || true)
  living=$(printf '%s\n' "$list" | potions_door_select_living) || true
  printf '%s' "$living"
}

# Map one key to quit|begin|notes|resume|noop. Resume is inert without a mood.
# Movement keys are handled by the loop; they are not actions.
potions_door_key_action() {
  local key="$1"
  local living="${2:-}"
  case "$key" in
    q|Q|esc) printf 'quit' ;;
    b|B) printf 'begin' ;;
    n|N) printf 'notes' ;;
    r|R)
      if [ -n "$living" ]; then
        printf 'resume'
      else
        printf 'noop'
      fi
      ;;
    *) printf 'noop' ;;
  esac
}

# One menu row per line: id|key|label|detail
# The empty door must not contain the word Resume. Tests depend on that.
potions_door_menu_lines() {
  local living="${1:-}"
  local begin_detail="mint a new mood"
  if potions_door_pinned_name >/dev/null 2>&1; then
    begin_detail="open the pinned mood"
  fi
  if [ -n "$living" ]; then
    printf 'resume|r|Resume|rejoin %s\n' "$living"
  fi
  printf 'begin|b|Begin|%s\n' "$begin_detail"
  printf 'notes|n|Notes|Neovim, then back here\n'
  printf 'quit|q|Quit|a normal shell, no session\n'
}

potions_door_menu_count() {
  potions_door_menu_lines "$1" | grep -c .
}

potions_door_menu_field() {
  local living="$1"
  local index="$2"
  local field="$3"
  local line
  line=$(potions_door_menu_lines "$living" | sed -n "$((index + 1))p")
  case "$field" in
    id) printf '%s' "${line%%|*}" ;;
    key)
      line="${line#*|}"
      printf '%s' "${line%%|*}"
      ;;
    *)
      line="${line#*|}"
      line="${line#*|}"
      if [ "$field" = "label" ]; then
        printf '%s' "${line%%|*}"
      else
        printf '%s' "${line#*|}"
      fi
      ;;
  esac
}

_potions_door_rule() {
  local ch="$1"
  local n="$2"
  local i=0
  local out=""
  while [ "$i" -lt "$n" ]; do
    out="${out}${ch}"
    i=$((i + 1))
  done
  printf '%s' "$out"
}

# Faint (SGR 2) disappears in several terminals. A hint is a sentence.
_potions_door_quiet() {
  _potions_quiet_color
}

# One inner row with no text. Used as air around the bottle.
_potions_door_span() {
  local v="$1"
  local inner="$2"
  local spaces
  spaces=$(_potions_door_rule " " "$inner")
  if [ "$POTIONS_HAS_COLOR" = true ]; then
    printf "${POTIONS_COLOR_BRAND}%s${POTIONS_NC}%s${POTIONS_COLOR_BRAND}%s${POTIONS_NC}\n" \
      "$v" "$spaces" "$v"
  else
    printf "%s%s%s\n" "$v" "$spaces" "$v"
  fi
}

# Center $2 inside a frame of inner width $3. $4 is the text color, or empty.
_potions_door_center_line() {
  local v="$1"
  local text="$2"
  local inner="$3"
  local color="${4:-}"
  local pad left right
  pad=$((inner - 2 - ${#text}))
  if [ "$pad" -lt 0 ]; then
    pad=0
  fi
  left=$((pad / 2))
  right=$((pad - left))
  if [ -n "$color" ] && [ "$POTIONS_HAS_COLOR" = true ]; then
    printf "${POTIONS_COLOR_BRAND}%s${POTIONS_NC}%s${color}%s${POTIONS_NC}%s${POTIONS_COLOR_BRAND}%s${POTIONS_NC}\n" \
      "$v" "$(_potions_door_rule " " "$left")" "$text" "$(_potions_door_rule " " "$((right + 2))")" "$v"
  else
    printf "%s%s%s%s%s\n" "$v" "$(_potions_door_rule " " "$left")" "$text" "$(_potions_door_rule " " "$((right + 2))")" "$v"
  fi
}

# Mood card plus a selectable list. The highlighted row is the one Enter opens.
# Letter keys still jump straight to an action.
potions_door_render() {
  local living="${1:-}"
  local index="${2:-0}"
  local pinned_name="" mood_name mood_line quiet
  local width inner line_no row_id row_label row_detail row_key row_plain detail_width cols
  local H TL TR BL BR V

  detect_terminal_capabilities
  # A fixed measure, narrower than the modal, so the block can sit in the middle.
  width=68
  cols=$(tput cols 2>/dev/null || echo 0)
  case "$cols" in
    ''|*[!0-9]*) cols=0 ;;
  esac
  if [ "$cols" -gt 0 ] && [ "$cols" -lt $((width + 2)) ]; then
    width=$((cols - 2))
  fi
  if [ "$width" -lt 48 ]; then
    width=48
  fi
  inner=$((width - 4))
  POTIONS_DOOR_BLOCK_WIDTH=$((width - 2))

  # The Linux console keeps a 256-glyph font. Double-line Unicode is the first thing it drops.
  if [ "${TERM:-}" = "linux" ] || [ "$POTIONS_HAS_UNICODE" != true ]; then
    H="="; TL="+"; TR="+"; BL="+"; BR="+"; V="|"
  else
    H="═"; TL="╔"; TR="╗"; BL="╚"; BR="╝"; V="║"
  fi

  local rows breath bottle_color
  rows=$(tput lines 2>/dev/null || echo 0)
  case "$rows" in
    ''|*[!0-9]*) rows=0 ;;
  esac
  breath=false
  if [ "$rows" -ge 28 ]; then
    breath=true
  fi
  bottle_color=""
  if [ "$POTIONS_HAS_COLOR" = true ]; then
    bottle_color="${POTIONS_COLOR_WARM:-$POTIONS_COLOR_KEY}"
  fi

  if [ "$POTIONS_HAS_COLOR" = true ]; then
    printf "${POTIONS_COLOR_BRAND}%s%s%s${POTIONS_NC}\n" "$TL" "$(_potions_door_rule "$H" "$inner")" "$TR"
  else
    printf "%s%s%s\n" "$TL" "$(_potions_door_rule "$H" "$inner")" "$TR"
  fi
  if [ "$breath" = true ]; then
    _potions_door_span "$V" "$inner"
  fi
  _potions_door_center_line "$V" "  _  " "$inner" "$bottle_color"
  _potions_door_center_line "$V" " ( ) " "$inner" "$bottle_color"
  _potions_door_center_line "$V" "/___\\" "$inner" "$bottle_color"
  if [ "$breath" = true ]; then
    _potions_door_span "$V" "$inner"
  fi
  _potions_door_center_line "$V" "potions" "$inner" "$POTIONS_COLOR_KEY"
  _potions_door_center_line "$V" "your cozy dev environment" "$inner" "$POTIONS_COLOR_DIM"
  if [ "$POTIONS_HAS_COLOR" = true ]; then
    printf "${POTIONS_COLOR_BRAND}%s%s%s${POTIONS_NC}\n" "$BL" "$(_potions_door_rule "$H" "$inner")" "$BR"
  else
    printf "%s%s%s\n" "$BL" "$(_potions_door_rule "$H" "$inner")" "$BR"
  fi

  if [ -n "$living" ]; then
    mood_name="$living"
    mood_line="living, as you left it"
  elif pinned_name=$(potions_door_pinned_name); then
    mood_name="$pinned_name"
    mood_line="pinned, not running yet"
  else
    mood_name="no mood yet"
    mood_line="Begin mints a name"
  fi

  echo ""
  if [ "$POTIONS_HAS_COLOR" = true ]; then
    printf "${POTIONS_COLOR_BRAND}%s%s%s${POTIONS_NC}\n" "$TL" "$(_potions_door_rule "$H" "$inner")" "$TR"
    printf "${POTIONS_COLOR_BRAND}%s${POTIONS_NC}  ${POTIONS_COLOR_KEY}%-$((inner - 2))s${POTIONS_NC}${POTIONS_COLOR_BRAND}%s${POTIONS_NC}\n" "$V" "$mood_name" "$V"
    quiet=$(_potions_door_quiet)
    if [ -n "$quiet" ]; then
      printf "${POTIONS_COLOR_BRAND}%s${POTIONS_NC}  ${quiet}%-$((inner - 2))s${POTIONS_NC}${POTIONS_COLOR_BRAND}%s${POTIONS_NC}\n" "$V" "$mood_line" "$V"
    else
      printf "${POTIONS_COLOR_BRAND}%s${POTIONS_NC}  %-*s${POTIONS_COLOR_BRAND}%s${POTIONS_NC}\n" "$V" "$((inner - 2))" "$mood_line" "$V"
    fi
    printf "${POTIONS_COLOR_BRAND}%s%s%s${POTIONS_NC}\n" "$BL" "$(_potions_door_rule "$H" "$inner")" "$BR"
  else
    printf "%s%s%s\n" "$TL" "$(_potions_door_rule "$H" "$inner")" "$TR"
    printf "%s  %-*s%s\n" "$V" "$((inner - 2))" "$mood_name" "$V"
    printf "%s  %-*s%s\n" "$V" "$((inner - 2))" "$mood_line" "$V"
    printf "%s%s%s\n" "$BL" "$(_potions_door_rule "$H" "$inner")" "$BR"
  fi

  echo ""
  if [ "$POTIONS_HAS_COLOR" = true ]; then
    printf "${POTIONS_COLOR_BRAND}%s%s%s${POTIONS_NC}\n" "$TL" "$(_potions_door_rule "$H" "$inner")" "$TR"
  else
    printf "%s%s%s\n" "$TL" "$(_potions_door_rule "$H" "$inner")" "$TR"
  fi
  line_no=0
  detail_width=$((inner - 15))
  if [ "$detail_width" -lt 0 ]; then
    detail_width=0
  fi
  while IFS= read -r row_id; do
    [ -n "$row_id" ] || continue
    row_label=$(potions_door_menu_field "$living" "$line_no" label)
    row_detail=$(potions_door_menu_field "$living" "$line_no" detail)
    row_key=$(potions_door_menu_field "$living" "$line_no" key)
    if [ "${#row_detail}" -gt "$detail_width" ]; then
      row_detail="${row_detail:0:detail_width}"
    fi
    row_plain=$(printf '  %-8s  %-*s  %s' "$row_label" "$detail_width" "$row_detail" "$row_key")
    if [ "$line_no" -eq "$index" ]; then
      if [ "$POTIONS_HAS_COLOR" = true ] && [ -n "${POTIONS_CTERM_PRIMARY:-}" ] && [ -n "${POTIONS_CTERM_SURFACE:-}" ]; then
        printf "${POTIONS_COLOR_BRAND}%s${POTIONS_NC}\033[1;48;5;%s;38;5;%sm%s\033[0m${POTIONS_COLOR_BRAND}%s${POTIONS_NC}\n" \
          "$V" "$POTIONS_CTERM_PRIMARY" "${POTIONS_CTERM_SELECT_FG:-$POTIONS_CTERM_SURFACE}" "$row_plain" "$V"
      elif [ "$POTIONS_HAS_COLOR" = true ]; then
        printf "${POTIONS_COLOR_BRAND}%s${POTIONS_NC}\033[7m%s\033[0m${POTIONS_COLOR_BRAND}%s${POTIONS_NC}\n" "$V" "$row_plain" "$V"
      else
        printf "%s>%s%s\n" "$V" "${row_plain# }" "$V"
      fi
    elif [ "$POTIONS_HAS_COLOR" = true ]; then
      quiet=$(_potions_door_quiet)
      if [ -n "$quiet" ]; then
        printf "${POTIONS_COLOR_BRAND}%s${POTIONS_NC}  ${POTIONS_COLOR_KEY}%-8s${POTIONS_NC}  ${POTIONS_COLOR_VALUE}%-*s${POTIONS_NC}  ${quiet}%s${POTIONS_NC}${POTIONS_COLOR_BRAND}%s${POTIONS_NC}\n" \
          "$V" "$row_label" "$detail_width" "$row_detail" "$row_key" "$V"
      else
        printf "${POTIONS_COLOR_BRAND}%s${POTIONS_NC}  ${POTIONS_COLOR_KEY}%-8s${POTIONS_NC}  ${POTIONS_COLOR_VALUE}%-*s${POTIONS_NC}  %s${POTIONS_COLOR_BRAND}%s${POTIONS_NC}\n" \
          "$V" "$row_label" "$detail_width" "$row_detail" "$row_key" "$V"
      fi
    else
      printf "%s%s%s\n" "$V" "$row_plain" "$V"
    fi
    line_no=$((line_no + 1))
  done <<EOF
$(potions_door_menu_lines "$living" | cut -d'|' -f1)
EOF
  if [ "$POTIONS_HAS_COLOR" = true ]; then
    printf "${POTIONS_COLOR_BRAND}%s%s%s${POTIONS_NC}\n" "$BL" "$(_potions_door_rule "$H" "$inner")" "$BR"
  else
    printf "%s%s%s\n" "$BL" "$(_potions_door_rule "$H" "$inner")" "$BR"
  fi

  if [ -n "${POTIONS_DOOR_NOTICE:-}" ]; then
    echo ""
    render_note_row "$POTIONS_DOOR_NOTICE"
  fi

  echo ""
  if [ "$POTIONS_HAS_COLOR" = true ]; then
    quiet=$(_potions_door_quiet)
    if [ -n "$quiet" ]; then
      printf "  ${quiet}j k move    enter open${POTIONS_NC}\n"
    else
      printf "  j k move    enter open\n"
    fi
  else
    printf "  j k move    enter open\n"
  fi
  echo ""
}

_potions_door_tty_saved=""

potions_door_tty_enter() {
  if [ -n "$_potions_door_tty_saved" ]; then
    return 0
  fi
  if [ -t 0 ]; then
    _potions_door_tty_saved=$(stty -g 2>/dev/null || true)
    # -icrnl keeps Enter as CR. Otherwise read treats it as a line ending and drops it.
    stty -echo -icanon -icrnl min 1 time 0 2>/dev/null || true
  fi
  if [ -t 1 ]; then
    printf '\033[?1049h\033[?25l'
  fi
}

potions_door_tty_leave() {
  if [ -t 1 ]; then
    printf '\033[?25h\033[?1049l'
  fi
  if [ -n "$_potions_door_tty_saved" ] && [ -t 0 ]; then
    stty "$_potions_door_tty_saved" 2>/dev/null || stty sane 2>/dev/null || true
  fi
  _potions_door_tty_saved=""
}

# Empty means Enter: read consumes a newline and leaves the variable blank.
potions_door_classify_key() {
  local key="$1"
  case "$key" in
    ""|$'\r'|$'\n') printf 'enter' ;;
    *) printf '%s' "$key" ;;
  esac
}

potions_door_read_key() {
  local key="" rest=""
  if [ ! -t 0 ]; then
    return 1
  fi
  IFS= read -r -n 1 key || return 1
  if [ "$key" = "$(printf '\033')" ]; then
    stty -echo -icanon -icrnl min 0 time 1 2>/dev/null || true
    IFS= read -r -n 2 rest || true
    stty -echo -icanon -icrnl min 1 time 0 2>/dev/null || true
    case "$rest" in
      '[A') printf 'up' ;;
      '[B') printf 'down' ;;
      *) printf 'esc' ;;
    esac
    return 0
  fi
  potions_door_classify_key "$key"
}

# One write, cursor home, erase below. The block sits in the middle of the pane.
potions_door_present() {
  local frame cols rows lines left top pad line placed i
  frame=$(potions_door_render "$1" "$2"; printf x)
  frame="${frame%x}"
  if [ ! -t 1 ]; then
    printf '%s' "$frame"
    return 0
  fi
  cols=$(tput cols 2>/dev/null || echo 0)
  rows=$(tput lines 2>/dev/null || echo 0)
  lines=$(printf '%s' "$frame" | wc -l | tr -d ' ')
  left=0
  top=0
  case "$cols" in
    ''|*[!0-9]*) cols=0 ;;
  esac
  case "$rows" in
    ''|*[!0-9]*) rows=0 ;;
  esac
  case "$lines" in
    ''|*[!0-9]*) lines=0 ;;
  esac
  if [ "$cols" -gt "${POTIONS_DOOR_BLOCK_WIDTH:-0}" ]; then
    left=$(( (cols - POTIONS_DOOR_BLOCK_WIDTH) / 2 ))
  fi
  if [ "$rows" -gt "$lines" ]; then
    top=$(( (rows - lines) / 2 ))
  fi
  pad=$(_potions_door_rule " " "$left")
  placed=""
  i=0
  while [ "$i" -lt "$top" ]; do
    placed="${placed}"$'\n'
    i=$((i + 1))
  done
  while IFS= read -r line || [ -n "$line" ]; do
    placed="${placed}${pad}${line}"$'\n'
  done <<EOF
$frame
EOF
  printf '\033[H%s\033[J' "$placed"
}

potions_door_config_dir() {
  printf '%s' "${POTIONS_HOME:-$HOME/.potions}/zellij"
}

# Outside a session: the zsh helpers own attach / attach --create.
# Inside a session: create in the background and switch, so the client does not nest.
potions_door_resume() {
  local name="$1"
  local config_dir attach_err
  potions_door_valid_session_name "$name" || return 0
  if [ -n "${ZELLIJ:-}" ]; then
    config_dir=$(potions_door_config_dir)
    zellij --config-dir "$config_dir" action switch-session "$name" || true
    return 0
  fi
  attach_err=$(mktemp)
  potions_door_zsh_call _potions_resume_mood "$name" 2>"$attach_err" || true
  if grep -q "another client" "$attach_err" 2>/dev/null; then
    POTIONS_DOOR_NOTICE="That mood is open in another terminal."
  fi
  rm -f "$attach_err"
}

potions_door_begin() {
  local name config_dir
  if [ -n "${ZELLIJ:-}" ]; then
    if ! name=$(potions_door_pinned_name); then
      name=$(potions_door_mint_name) || return 0
    fi
    potions_door_valid_session_name "$name" || return 0
    config_dir=$(potions_door_config_dir)
    env -u ZELLIJ zellij --config-dir "$config_dir" attach --create-background "$name" || true
    zellij --config-dir "$config_dir" action switch-session "$name" || true
    return 0
  fi
  potions_door_zsh_call _potions_begin_mood "" || true
}

potions_door_notes() {
  if ! command -v nvim >/dev/null 2>&1; then
    POTIONS_DOOR_NOTICE="Neovim is not installed. Staying on the door."
    return 0
  fi
  potions_door_tty_leave
  nvim || true
  potions_door_tty_enter
  POTIONS_DOOR_NOTICE=""
}

potions_door_clamp_index() {
  local living="$1"
  local index="$2"
  local count
  count=$(potions_door_menu_count "$living")
  if [ "$count" -lt 1 ]; then
    printf '0'
    return 0
  fi
  if [ "$index" -lt 0 ]; then
    index=$((count - 1))
  fi
  if [ "$index" -ge "$count" ]; then
    index=0
  fi
  printf '%s' "$index"
}

potions_door_run_action() {
  local action="$1"
  local living="$2"
  case "$action" in
    quit)
      return 1
      ;;
    begin)
      potions_door_tty_leave
      potions_door_begin
      return 2
      ;;
    resume)
      potions_door_tty_leave
      potions_door_resume "$living"
      return 2
      ;;
    notes)
      potions_door_notes
      return 0
      ;;
    *)
      return 0
      ;;
  esac
}

potions_door_loop() {
  local living="" key="" action="" index=0 count=0 status=0
  potions_door_tty_enter
  while true; do
    living=$(potions_door_living_name || true)
    count=$(potions_door_menu_count "$living")
    index=$(potions_door_clamp_index "$living" "$index")
    potions_door_present "$living" "$index"
    POTIONS_DOOR_NOTICE=""
    if ! key=$(potions_door_read_key); then
      break
    fi
    case "$key" in
      up|k|K)
        index=$((index - 1))
        continue
        ;;
      down|j|J)
        index=$((index + 1))
        continue
        ;;
      enter)
        action=$(potions_door_menu_field "$living" "$index" id)
        ;;
      *)
        action=$(potions_door_key_action "$key" "$living")
        if [ "$action" = "noop" ] && { [ "$key" = "r" ] || [ "$key" = "R" ]; }; then
          POTIONS_DOOR_NOTICE="No living mood to resume."
        fi
        ;;
    esac
    potions_door_run_action "$action" "$living"
    status=$?
    if [ "$status" -eq 1 ]; then
      break
    fi
    if [ "$status" -eq 2 ]; then
      return 0
    fi
    if [ "$count" -gt 0 ] && [ "$index" -ge "$count" ]; then
      index=0
    fi
  done
  potions_door_tty_leave
  return 0
}

potions_door_main() {
  if [ ! -t 0 ] || [ ! -t 1 ]; then
    return 0
  fi
  trap 'potions_door_tty_leave; exit 0' INT TERM
  trap 'potions_door_tty_leave' EXIT
  potions_door_loop || true
}
