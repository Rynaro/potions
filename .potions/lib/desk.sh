#!/bin/bash
# The interactive Potions Desk. The foreground CLI owns and restores its tty.

_desk_enter() {
  screen_active=true
  printf '\033[?1049h\033[?25l'
  stty -echo -icanon -ixon min 1 time 0
}

_desk_leave() {
  if [ "$screen_active" = true ]; then
    stty "$saved_tty" 2>/dev/null || :
    printf '%s\033[?25h\033[?1049l' "$reset"
    screen_active=false
  fi
}

# Keep dynamic text within a row. Budget two cells for non-ASCII text so wide
# filenames fit too. All chrome and column headings have known cell widths.
_desk_clip() {
  local text="$1" limit="$2" count=0 cells=0 char ascii='^[ -~]*$'
  clipped="${text//[[:cntrl:]]/ }"
  [ -n "$clipped" ] || return 0
  if [[ "$clipped" =~ $ascii ]]; then
    clipped="${clipped:0:limit}"
    return 0
  fi
  while [ "$count" -lt "${#clipped}" ]; do
    char="${clipped:count:1}"
    if [[ "$char" =~ $ascii ]]; then cells=$((cells + 1))
    else cells=$((cells + 2)); fi
    [ "$cells" -le "$limit" ] || break
    count=$((count + 1))
  done
  clipped="${clipped:0:count}"
}

# Position cells independently and send the completed frame in a single write.
_desk_put() {
  local pos
  printf -v pos '\033[%d;%dH' "$1" "$2"
  frame+="$pos$3$4$reset"
}

_desk_text() {
  _desk_clip "$4" "$5"
  _desk_put "$1" "$2" "$3" "$clipped"
}

_desk_clip_path() {
  local path="$1" limit="$2" head_limit cells=0 char tail_start ascii='^[ -~]$' home_marker='~'
  if [ -n "$display_home" ]; then
    case "$path" in
      "$display_home"|"$physical_home") path="$home_marker" ;;
      "$display_home/"*) path="$home_marker/${path#"$display_home/"}" ;;
      "$physical_home/"*) path="$home_marker/${path#"$physical_home/"}" ;;
    esac
  fi
  path="${path//[[:cntrl:]]/ }"
  _desk_clip "$path" "$limit"
  if [ "$clipped" = "$path" ] || [ "$limit" -lt 5 ]; then return 0; fi

  # Keep the start of the path and more cells for its trailing components.
  head_limit=$(((limit - 3) / 3))
  tail_start="${#path}"
  while [ "$tail_start" -gt 0 ]; do
    char="${path:tail_start-1:1}"
    if [[ "$char" =~ $ascii ]]; then cells=$((cells + 1))
    else cells=$((cells + 2)); fi
    [ "$cells" -le $((limit - head_limit - 3)) ] || break
    tail_start=$((tail_start - 1))
  done
  _desk_clip "$path" "$head_limit"
  clipped="$clipped...${path:tail_start}"
}

_desk_size() {
  local dims
  dims=$(stty size 2>/dev/null) || return 1
  read -r rows cols <<< "$dims"
  [[ "$rows" =~ ^[0-9]+$ && "$rows" -gt 0 ]] || rows=24
  [[ "$cols" =~ ^[0-9]+$ && "$cols" -gt 0 ]] || cols=80
  width=$cols
  if [ "$width" -gt 88 ]; then width=88
  elif [ "$width" -gt 46 ]; then width=$((width - 4)); fi
  height=$rows
  [ "$height" -le 23 ] || height=23
  header_rows=2
  if [ "$view" = home ] && [ "$width" -ge 59 ] && [ "$rows" -ge 16 ]; then header_rows=4; fi
  if [ "$view" = projects ] && [ "$rows" -ge 9 ] && [ -n "$project_notice" ]; then header_rows=3; fi
  local home_height=$((${#action_ids[@]} + header_rows + 5))
  if [ "$view" = home ] && [ "$height" -gt "$home_height" ]; then height=$home_height; fi
  left=$(((cols - width) / 2 + 1))
  top=$(((rows - height) / 2 + 1))
  body_width=$((width - 6))
  visible=$((height - header_rows - 5))
}

_desk_filter() {
  local i against restore_case=false
  if ! shopt -q nocasematch; then shopt -s nocasematch; restore_case=true; fi
  matches=()
  for ((i=0; i<${#key_names[@]}; i++)); do
    against="${sections[i]} ${key_names[i]} ${descriptions[i]}"
    if [[ "$against" == *"$query"* ]]; then
      matches+=("$i")
    fi
  done
  if [ "$restore_case" = true ]; then shopt -u nocasematch; fi
  key_cursor=0
  offset=0
}

_desk_load_keys() {
  if [ "${#key_names[@]}" -eq 0 ]; then
    local group name description
    while IFS=$'\t' read -r group name description; do
      [ -n "$name" ] || continue
      sections+=("$group")
      key_names+=("$name")
      descriptions+=("$description")
    done < <(desk_shortcuts)
  fi
  _desk_filter
  view=keys
}

_desk_load_projects() {
  local path
  project_paths=()
  while IFS= read -r -d '' path; do
    if [[ "$path" != /* ]]; then
      project_notice='Cannot read pins.'
      break
    fi
    project_paths+=("$path")
  done < <(desk_project_paths 2>/dev/null || printf '\0')
}

_desk_show_projects() {
  view=projects
  project_notice=''
  project_cursor=0
  offset=0
  _desk_load_projects
}

_desk_change_pins() {
  local message cwd i
  case "$1" in
    p)
      if message=$(desk_project_pin 2>&1); then
        project_notice='Pinned current folder.'
        _desk_load_projects
        cwd=$(pwd -P) || return 0
        for i in "${!project_paths[@]}"; do
          if [ "${project_paths[i]}" = "$cwd" ]; then
            project_cursor="$i"
            break
          fi
        done
      else
        project_notice="${message:-Could not pin this folder.}"
      fi
      ;;
    u)
      if [ "${#project_paths[@]}" -eq 0 ]; then return 0; fi
      if message=$(desk_project_unpin "${project_paths[project_cursor]}" 2>&1); then
        project_notice='Project unpinned.'
        _desk_load_projects
      else
        project_notice="${message:-Could not unpin this project.}"
      fi
      ;;
  esac
}

_desk_load_report() {
  local line
  lines=()
  while IFS= read -r line || [ -n "$line" ]; do
    lines+=("$line")
  done < <(desk_report "$1" 2>&1)
  [ "${#lines[@]}" -gt 0 ] || lines=("No output.")
  view="$1"
  offset=0
  wrap_width=0
}

_desk_wrap() {
  local line remaining
  wrapped=()
  for line in "${lines[@]}"; do
    remaining="${line//[[:cntrl:]]/ }"
    if [ -z "$remaining" ]; then wrapped+=(""); continue; fi
    while [ -n "$remaining" ]; do
      _desk_clip "$remaining" "$body_width"
      wrapped+=("$clipped")
      remaining="${remaining:${#clipped}}"
    done
  done
  wrap_width=$body_width
}

_desk_move() {
  local step="$1"
  case "$view" in
    home) home_cursor=$((home_cursor + step)) ;;
    keys) key_cursor=$((key_cursor + step)) ;;
    projects)
      if [ "${#project_paths[@]}" -gt 0 ]; then
        project_cursor=$((project_cursor + step))
        project_notice=''
      fi
      ;;
    *) offset=$((offset + step)) ;;
  esac
}

_desk_render() {
  local heading context footer total selected=-1 item i y row color label
  local right bottom inner rule space marker info header_x header_y section_y secondary context_limit
  frame=$'\033[H\033[2J'
  if [ "$cols" -lt 24 ] || [ "$rows" -lt 8 ]; then
    _desk_text 1 1 "$bold" 'Potions Desk' "$cols"
    if [ "$rows" -ge 2 ]; then _desk_text 2 1 '' 'Resize to 24x8 or press q' "$cols"; fi
    printf '%s' "$frame"
    return
  fi

  right=$((left + width - 1))
  bottom=$((top + height - 1))
  inner=$((width - 2))
  context_limit=$((width - 5))
  if [ "$header_rows" -eq 4 ]; then context_limit=$((context_limit - 8)); fi
  printf -v space '%*s' "$inner" ''
  rule="${space// /$horizontal}"
  case "$view" in
    home)
      heading='Potions Desk'
      if [ -n "$notice" ]; then
        context="$notice"
      else
        context=''
        if [ "$width" -ge 35 ]; then context='Workspace  '; fi
        _desk_clip_path "$PWD" $((context_limit - ${#context}))
        context+="$clipped"
      fi
      total=${#action_ids[@]}
      selected=$home_cursor
      footer='Up/Down or j/k   Enter Open   / Shortcuts   q Close'
      [ "$body_width" -ge 49 ] || footer='j/k Move  Enter Open  q Close'
      ;;
    keys)
      heading='Keyboard shortcuts'
      total=${#matches[@]}
      selected=$key_cursor
      context="$total shortcuts"
      if [ "$editing" = true ]; then
        context="/ ${query}_"
        footer='Type to filter   Enter Apply   Esc Clear'
        [ "$body_width" -ge 40 ] || footer='Enter Apply  Esc Clear'
      else
        [ -z "$query" ] || context="$total matches  / $query"
        footer='j/k Move   / Search   Enter Details   Esc Back   q Close'
        [ "$body_width" -ge 56 ] || footer='/ Search  Enter Details  Esc Back'
      fi
      ;;
    projects)
      heading='Projects'
      _desk_clip_path "$PWD" $((context_limit - 9))
      context="Current: $clipped"
      if [ "$header_rows" -eq 2 ] && [ -n "$project_notice" ]; then context="$project_notice"; fi
      total=${#project_paths[@]}
      selected=$project_cursor
      footer='j/k Move   Enter Switch   p Pin   u Unpin   Esc Back   q Close'
      if [ "$width" -lt 65 ]; then footer='Enter Switch  p Pin  u Unpin  Esc  q'; fi
      if [ "$total" -eq 0 ]; then footer='p Pin current folder   Esc Back   q Close'; fi
      ;;
    *)
      if [ "$wrap_width" -ne "$body_width" ]; then _desk_wrap; fi
      total=${#wrapped[@]}
      case "$view" in
        git) heading='Working tree' ;;
        doctor) heading='Health check' ;;
        detail) heading="${key_names[detail_index]}" ;;
      esac
      context="$workspace"
      [ "$view" != detail ] || context="${sections[detail_index]} shortcuts"
      footer='j/k Scroll   PgUp/PgDn Page   Esc Back   q Close'
      [ "$body_width" -ge 48 ] || footer='j/k Scroll  Esc Back  q Close'
      ;;
  esac

  if [ "$view" = home ] || [ "$view" = keys ] || [ "$view" = projects ]; then
    [ "$selected" -lt "$total" ] || selected=$((total - 1))
    [ "$selected" -ge 0 ] || selected=0
    case "$view" in
      home) home_cursor=$selected ;;
      keys) key_cursor=$selected ;;
      projects) project_cursor=$selected ;;
    esac
    [ "$offset" -le "$selected" ] || offset=$selected
    [ "$offset" -gt $((selected - visible)) ] || offset=$((selected - visible + 1))
  fi
  [ "$offset" -le $((total - visible)) ] || offset=$((total - visible))
  [ "$offset" -ge 0 ] || offset=0

  _desk_put "$top" "$left" "$accent" "$tl$rule$tr"
  for ((y=top+1; y<bottom; y++)); do
    _desk_put "$y" "$left" "$accent" "$vertical"
    _desk_put "$y" "$right" "$accent" "$vertical"
  done
  _desk_put "$bottom" "$left" "$accent" "$bl$rule$br"
  section_y=$((top + header_rows + 1))
  _desk_put "$section_y" "$left" "$accent" "$join_left$rule$join_right"
  _desk_put $((bottom - 2)) "$left" "$accent" "$join_left$rule$join_right"
  header_x=$((left + 3))
  header_y=$((top + 1))
  if [ "$header_rows" -eq 4 ]; then
    _desk_put "$header_y" "$header_x" "$accent" '  __'
    _desk_put $((header_y + 1)) "$header_x" "$accent" '  ||'
    _desk_put $((header_y + 2)) "$header_x" "$accent" " /~~\\"
    _desk_put $((header_y + 3)) "$header_x" "$accent" ' \__/'
    header_x=$((header_x + 8))
    header_y=$((header_y + 1))
  fi
  _desk_text "$header_y" "$header_x" "$bold" "$heading" $((right - header_x - 1))
  if [ "$view" = home ]; then info="$version"; else info='Potions Desk'; fi
  if [ "$width" -ge 52 ]; then
    _desk_text "$header_y" $((right - ${#info} - 2)) "$muted" "$info" "${#info}"
  fi
  _desk_text $((header_y + 1)) "$header_x" "$muted" "$context" $((right - header_x - 1))
  if [ "$view" = projects ] && [ "$header_rows" -eq 3 ]; then
    _desk_text $((header_y + 2)) "$header_x" "$muted" "$project_notice" "$context_limit"
  fi

  for ((row=0; row<visible && offset+row<total; row++)); do
    i=$((offset + row))
    y=$((section_y + 1 + row))
    if [ "$selected" -ge 0 ]; then
      marker='  '; color=''; secondary=$muted
      if [ "$i" -eq "$selected" ]; then
        color=$highlight; secondary=$highlight; marker="$pointer "
        _desk_put "$y" $((left + 1)) "$color" "$space"
      fi
      _desk_put "$y" $((left + 2)) "$color" "$marker"
      if [ "$view" = home ]; then
        label="${action_titles[i]}"
        _desk_text "$y" $((left + 4)) "$color" "$label" "$body_width"
        if [ "$width" -ge 59 ]; then
          _desk_text "$y" $((left + 27)) "$secondary" "${action_hints[i]}" $((width - 30))
        fi
      elif [ "$view" = projects ]; then
        _desk_clip_path "${project_paths[i]}" "$body_width"
        _desk_put "$y" $((left + 4)) "$color" "$clipped"
      else
        item="${matches[i]}"
        if [ "$width" -ge 66 ]; then
          _desk_text "$y" $((left + 4)) "$color" "${sections[item]}" 11
          _desk_text "$y" $((left + 16)) "$color" "${key_names[item]}" 18
          _desk_text "$y" $((left + 36)) "$color" "${descriptions[item]}" $((width - 38))
        else
          label="${key_names[item]}  ${descriptions[item]}"
          _desk_text "$y" $((left + 4)) "$color" "$label" $((body_width - 1))
        fi
      fi
    else
      _desk_put "$y" $((left + 3)) '' "${wrapped[i]}"
    fi
  done
  if [ "$view" = keys ] && [ "$total" -eq 0 ]; then
    _desk_text $((section_y + 1)) $((left + 3)) '' 'No matching shortcuts' "$body_width"
  elif [ "$view" = projects ] && [ "$total" -eq 0 ]; then
    _desk_text $((section_y + 1)) $((left + 3)) '' 'No projects pinned' "$body_width"
  fi
  if [ "$total" -gt "$visible" ]; then
    local last=$((offset + visible))
    [ "$last" -le "$total" ] || last=$total
    local page=" $((offset + 1))-$last/$total "
    _desk_put $((bottom - 2)) $((right - ${#page} - 1)) "$muted" "$page"
  fi
  if [ "${#footer}" -gt "$inner" ]; then
    case "$view" in
      home) footer='j/k  Enter  /  q' ;;
      keys) if [ "$editing" = true ]; then footer='Enter Apply  Esc Clear'; else footer='j/k  /  Enter  Esc  q'; fi ;;
      projects)
        if [ "$total" -eq 0 ]; then footer='p Pin  Esc Back  q'
        else footer='Enter p+ u Unpin q'; fi
        ;;
      *) footer='j/k  Esc Back  q' ;;
    esac
  fi
  _desk_text $((bottom - 1)) $((left + 2)) "$muted" "$footer" $((inner - 1))
  printf '%s' "$frame"
}

_desk_activate() {
  local action rc
  case "$view" in
    home)
      action="${action_ids[home_cursor]}"
      case "$action" in
        keys) query=''; _desk_load_keys ;;
        projects) _desk_show_projects ;;
        git|doctor) _desk_load_report "$action" ;;
        tab)
          if notice=$(desk_new_tab 2>&1); then
            finished=true
          elif [ -z "$notice" ]; then
            notice='Could not open a terminal tab.'
          fi
          ;;
        plugins)
          _desk_leave
          notice=''
          if (cmd_plugin menu); then :
          else
            rc=$?
            notice="Plugin manager exited with status $rc."
          fi
          [ "$signal_status" -eq 0 ] || return 0
          _desk_enter || return 1
          ;;
        edit|notes)
          _desk_leave
          notice=''
          if desk_edit "$action"; then :
          else
            rc=$?
            notice="Editor exited with status $rc. Check VISUAL or EDITOR."
          fi
          [ "$signal_status" -eq 0 ] || return 0
          _desk_enter || return 1
          ;;
      esac
      ;;
    keys)
      if [ "${#matches[@]}" -gt 0 ]; then
        detail_index="${matches[key_cursor]}"
        lines=("${descriptions[detail_index]}")
        view=detail
        offset=0
        wrap_width=0
      fi
      ;;
    projects)
      if [ "${#project_paths[@]}" -eq 0 ]; then return 0; fi
      if builtin cd -P -- "${project_paths[project_cursor]}" >/dev/null 2>&1; then
        workspace="${PWD##*/}"
        [ -n "$workspace" ] || workspace=/
        view=home
        home_cursor=0
        offset=0
        notice=''
      else
        project_notice='Project unavailable. Press u to unpin.'
      fi
      ;;
  esac
}

# Bash 3 read -t accepts whole seconds only. A terminal inter-byte timeout
# lets a standalone Escape return promptly while allowing CSI/SS3 sequences.
_desk_escape() {
  local byte sequence=''
  stty min 0 time 1 || return 1
  byte=$(dd bs=1 count=1 2>/dev/null)
  case "$byte" in
    '['|'O')
      while [ "${#sequence}" -lt 12 ]; do
        byte=$(dd bs=1 count=1 2>/dev/null)
        [ -n "$byte" ] || break
        sequence+="$byte"
        case "$byte" in [A-Za-z~]) break ;; esac
      done
      case "$sequence" in
        A) key=UP ;; B) key=DOWN ;;
        5~) key=PAGE_UP ;; 6~) key=PAGE_DOWN ;;
        H|1~) key=FIRST ;; F|4~) key=LAST ;;
        *) key=UNKNOWN ;;
      esac
      ;;
    '') key=ESC ;;
    *) key=UNKNOWN ;;
  esac
  stty min 1 time 0
}

_desk_run() {
  local view=home editing=false finished=false query='' notice='' offset=0 home_cursor=0 key_cursor=0
  local project_cursor=0 project_notice='' project_paths=()
  local display_home="${HOME%/}" physical_home
  local detail_index=0 wrap_width=0 redraw=true key='' read_started
  local rows cols width height top left visible body_width header_rows frame clipped version workspace
  local sections=() key_names=() descriptions=() matches=() lines=() wrapped=()
  local action_ids=(edit notes git keys doctor)
  local action_titles=('Project editor' 'Scratchpad' 'Working tree' 'Keyboard shortcuts' 'Health check')
  local action_hints=('Open the current directory' 'Notes shared across projects' 'Branch and changed files' 'Search Zellij, Zsh and Neovim' 'Check this installation')
  if [ -n "${ZELLIJ:-}" ]; then
    action_ids+=(tab)
    action_titles+=('New terminal tab')
    action_hints+=('Open a shell in this directory')
  fi
  action_ids+=(plugins)
  action_titles+=('Plugins')
  action_hints+=('Install and manage GitHub or local plugins')
  action_ids+=(projects)
  action_titles+=('Projects')
  action_hints+=('Pin and switch folders')
  local accent='' muted='' bold='' highlight=''
  local tl='+' tr='+' bl='+' br='+' horizontal='-' vertical='|' join_left='+' join_right='+' pointer='>'
  detect_terminal_capabilities
  if [ "$POTIONS_HAS_COLOR" = true ]; then
    accent=$'\033[35m'; muted=$'\033[36m'; bold=$'\033[1m'
    highlight=$'\033[7m'; reset=$'\033[0m'
  fi
  if [ "$POTIONS_HAS_UNICODE" = true ]; then
    tl='╭'; tr='╮'; bl='╰'; br='╯'; horizontal='─'; vertical='│'
    join_left='├'; join_right='┤'; pointer='›'
  fi
  workspace="${PWD##*/}"
  [ -n "$workspace" ] || workspace=/
  if [ -n "$display_home" ]; then
    physical_home=$(builtin cd -P -- "$display_home" 2>/dev/null && printf '%s/' "$PWD") || physical_home="$display_home"
    physical_home="${physical_home%/}"
  fi
  version="v$(get_version)"
  _desk_clip "$version" 14; version=$clipped
  case "${1:-home}" in
    keys) _desk_load_keys ;;
    projects) _desk_show_projects ;;
  esac
  # Bash may run traps while read is still using the tty. Repaint or restore
  # the terminal only after read has returned and restored its own settings.
  trap 'redraw=true' WINCH
  _desk_enter || return 1

  while [ "$finished" = false ] && [ "$signal_status" -eq 0 ]; do
    if [ "$redraw" = true ]; then
      redraw=false
      _desk_size || return 1
      _desk_render
    fi
    if [ "$redraw" = true ] || [ "$signal_status" -ne 0 ]; then continue; fi
    read_started=$SECONDS
    # Bound the wait so resize and termination also work without key input.
    if ! IFS= read -r -n 1 -t 1 key; then
      if [ "$read_started" -eq "$SECONDS" ] && [ "$redraw" = false ]; then
        stty -g >/dev/null 2>&1 || return 0
      fi
      continue
    fi
    [ "$signal_status" -eq 0 ] || break
    if [ "$redraw" = true ]; then _desk_size || return 1; fi
    redraw=true
    case "$key" in
      $'\033') _desk_escape || return 1 ;;
      $'\004'|$'\003') return 0 ;;
      ''|$'\r') key=ENTER ;;
      $'\177'|$'\b') key=BACKSPACE ;;
    esac
    if [ "$cols" -lt 24 ] || [ "$rows" -lt 8 ]; then
      case "$key" in q|ESC) return 0 ;; esac
      continue
    fi
    if [ "$editing" = true ]; then
      case "$key" in
        ESC) query=''; editing=false; _desk_filter ;;
        ENTER) editing=false ;;
        BACKSPACE) query="${query%?}"; _desk_filter ;;
        UP) _desk_move -1 ;; DOWN) _desk_move 1 ;;
        ?) if [[ "$key" == [[:print:]] ]] && [ "${#query}" -lt 128 ]; then query+="$key"; _desk_filter; fi ;;
      esac
      continue
    fi
    case "$key" in
      q) return 0 ;;
      ESC|BACKSPACE)
        case "$view" in
          home) return 0 ;;
          detail) view=keys ;;
          keys) if [ -n "$query" ]; then query=''; _desk_filter; else view=home; fi ;;
          *) view=home ;;
        esac
        offset=0
        ;;
      /)
        case "$view" in
          home) query=''; _desk_load_keys; editing=true ;;
          keys) editing=true ;;
        esac
        ;;
      p|u) if [ "$view" = projects ]; then _desk_change_pins "$key"; fi ;;
      UP|k) _desk_move -1 ;;
      DOWN|j) _desk_move 1 ;;
      PAGE_UP) _desk_move $((-visible)) ;;
      PAGE_DOWN) _desk_move "$visible" ;;
      FIRST) _desk_move -10000000 ;;
      LAST) _desk_move 10000000 ;;
      ENTER) _desk_activate || return 1 ;;
    esac
  done
}

desk_open() {
  local saved_tty screen_active=false reset='' status=0 signal_status=0
  saved_tty=$(stty -g) || return 1
  trap '_desk_leave' EXIT
  trap 'signal_status=130' INT
  trap 'signal_status=143' TERM
  trap 'signal_status=129' HUP
  trap 'signal_status=148' TSTP
  _desk_run "$@" || status=$?
  _desk_leave
  trap - EXIT INT TERM HUP TSTP WINCH
  if [ "$signal_status" -ne 0 ]; then return "$signal_status"; fi
  return "$status"
}
