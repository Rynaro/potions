POTIONS_HOME="$HOME/.potions"

# Migration detection - check if legacy config needs migration
# Only show once per session
if [ -z "$POTIONS_MIGRATION_CHECKED" ]; then
  export POTIONS_MIGRATION_CHECKED=1
  if [ -f "$POTIONS_HOME/.zsh_aliases" ] && [ ! -f "$POTIONS_HOME/config/aliases.zsh" ]; then
    echo ""
    echo "⚠️  Potions v2.5.0: Legacy configuration detected"
    echo "   Run: curl -fsSL https://raw.githubusercontent.com/Rynaro/potions/main/migrate.sh | bash"
    echo ""
  fi
fi

is_linux() {
  [ "$(uname -s)" = "Linux" ]
}
# Function to check if the environment is Termux
is_termux() {
  [ -n "$PREFIX" ] && [ -x "$PREFIX/bin/termux-info" ]
}

# Function to check if the environment is WSL
is_wsl() {
  grep -qi microsoft /proc/version 2>/dev/null
}

# Function to check if the environment is macOS
is_macos() {
  [ "$(uname -s)" = "Darwin" ]
}

# Function to check if running in an AI code editor terminal (VSCode, Cursor, Claude Code, etc.)
# These terminals should not auto-start the multiplexer to avoid terminal output capture issues
is_ai_code_editor() {
  # Check for VSCode environment variables
  if [ -n "$VSCODE_INJECTION" ] || [ -n "$VSCODE_PID" ] || [ "$TERM_PROGRAM" = "vscode" ]; then
    return 0
  fi
  # Check for Cursor environment variables
  if [ -n "$CURSOR_TERMINAL" ] || [ "$TERM_PROGRAM" = "cursor" ]; then
    return 0
  fi
  # Check for other common AI editor indicators
  if [ -n "$INTELLIJ_TERMINAL" ] || [ "$TERM_PROGRAM" = "jetbrains" ]; then
    return 0
  fi
  # Claude Code sets CLAUDECODE=1; any non-empty value counts.
  if [ -n "$CLAUDECODE" ]; then
    return 0
  fi
  return 1
}

# Function to safely source a file if it exists
safe_source() {
  [ -f "$1" ] && source "$1"
}

# Load antidote plugin manager
safe_source "$POTIONS_HOME/.antidote/antidote.zsh"
if command -v antidote &> /dev/null; then
  antidote load
fi

# Neovim as the default editor
export PATH="$HOME/.neovim/bin:$PATH"
export EDITOR=nvim

# Potions CLI
export PATH="$POTIONS_HOME/bin:$PATH"

# Git Prompt configuration
# Wrap git_super_status in error handling to prevent prompt rendering issues
PROMPT='%F{cyan}%n%f%F{magenta}@%f%F{blue}%m%f:%b$(git_super_status 2>/dev/null || echo "") %~ %(#.#.$) '

if is_macos; then
  # macOS-specific configurations
  export PATH="/opt/homebrew/bin:$PATH"
  export PATH="$(brew --prefix openvpn)/sbin:$PATH"

  safe_source "$POTIONS_HOME/sources/macos.sh"
  safe_source "$HOME/.docker/init-zsh.sh"
elif ! is_termux && is_linux; then
  # Linux-based configurations
  safe_source "$POTIONS_HOME/sources/linux.sh"

  # Docker completion
  if [ -f "/usr/share/zsh/vendor-completions/_docker" ]; then
    fpath=("/usr/share/zsh/vendor-completions" $fpath)
  fi
fi

# Initialize command completion
autoload -Uz compinit && compinit

# Legacy aliases (for backwards compatibility)
safe_source "$POTIONS_HOME/.zsh_aliases"
safe_source "$POTIONS_HOME/.zsh_secure_aliases"

# User customizations - these files are preserved on upgrade
# Create these files to add your own configurations

# Main user aliases and functions
safe_source "$POTIONS_HOME/config/aliases.zsh"

# Sensitive/private aliases (not in version control)
safe_source "$POTIONS_HOME/config/secure.zsh"

# Machine-local configuration (not synced)
safe_source "$POTIONS_HOME/config/local.zsh"

# Load Potions plugins
# This sources all active plugin configurations
safe_source "$POTIONS_HOME/plugins/.init.zsh"

# Platform-specific user configurations
if is_macos; then
  safe_source "$POTIONS_HOME/config/macos.zsh"
elif is_linux && ! is_wsl && ! is_termux; then
  safe_source "$POTIONS_HOME/config/linux.zsh"
elif is_wsl; then
  safe_source "$POTIONS_HOME/config/wsl.zsh"
elif is_termux; then
  safe_source "$POTIONS_HOME/config/termux.zsh"
fi

# Potions theme — apply the active palette to the live terminal (best-effort).
# The theme generator writes config/generated/ansi-map.sh (OSC repaint +
# POTIONS_COLOR_* exports). Switch with: potions theme set <variant>.
# Inside Zellij the generated Zellij theme owns the palette, so this self-skips.
safe_source "$POTIONS_HOME/config/generated/ansi-map.sh"
if [[ -o interactive ]] && command -v potions_apply_terminal_palette &> /dev/null; then
  potions_apply_terminal_palette
fi

# Disable XON/XOFF flow control so Ctrl+S and Ctrl+Q are free for applications.
# Neovim binds Ctrl+S to "save"; without this, the terminal swallows Ctrl+S as
# XOFF and freezes all output until Ctrl+Q — making the advertised save look
# broken on every platform. Interactive TTY only; the [ -t 0 ] guard and the
# 2>/dev/null keep it silent in non-tty contexts (CI, piped shells, editors).
if [[ -o interactive ]] && [ -t 0 ]; then
  stty -ixon 2>/dev/null
fi

# Enable word navigation with Ctrl + arrow keys
# Terminal-specific key bindings for maximum compatibility
case "$TERM_PROGRAM" in
  iTerm.app)
    # iTerm2 sends these sequences for Ctrl+Arrow
    bindkey "^[[1;5C" forward-word  # Ctrl + Right Arrow
    bindkey "^[[1;5D" backward-word # Ctrl + Left Arrow
    ;;
  Apple_Terminal)
    # Terminal.app uses Alt+f/Alt+b for word navigation
    bindkey "^[f" forward-word  # Alt+f (Option+f)
    bindkey "^[b" backward-word # Alt+b (Option+b)
    # Also try standard sequences as fallback
    bindkey "^[[1;5C" forward-word
    bindkey "^[[1;5D" backward-word
    ;;
  vscode|cursor)
    # VS Code and Cursor terminals
    bindkey "^[[1;5C" forward-word
    bindkey "^[[1;5D" backward-word
    ;;
  *)
    # Default: bind all common sequences for maximum compatibility
    bindkey "^[[1;5C" forward-word  # Standard Ctrl + Right Arrow
    bindkey "^[[1;5D" backward-word # Standard Ctrl + Left Arrow
    bindkey "^[[5C" forward-word    # Alternative (multiplexer)
    bindkey "^[[5D" backward-word   # Alternative (multiplexer)
    bindkey "^[f" forward-word      # Alt+f fallback
    bindkey "^[b" backward-word     # Alt+b fallback
    ;;
esac

# Common bindings that work across all terminals
bindkey "^[[5C" forward-word    # Alternative sequence (multiplexer passthrough)
bindkey "^[[5D" backward-word   # Alternative sequence (multiplexer passthrough)

# History settings
HISTFILE=$POTIONS_HOME/.zsh_history   # Where to save the command history
HISTSIZE=10000                            # Number of commands to save in the history file
SAVEHIST=10000                            # Number of commands to keep in the internal history

# Share history across all Zsh sessions
setopt SHARE_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS
setopt INC_APPEND_HISTORY
setopt EXTENDED_HISTORY

# Append history to the history file, rather than overwriting it
setopt APPEND_HISTORY
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS

# Fix prompt rendering after CTRL+C (SIGINT)
# Reset terminal state and refresh prompt after interrupt
TRAPINT() {
    # Reset terminal to known good state
    [[ -t 0 ]] && stty sane 2>/dev/null
    # Force prompt refresh if in interactive mode
    if [[ -o interactive ]]; then
        zle && { zle .reset-prompt 2>/dev/null || true }
    fi
    return 128
}

# Pick a random two-word alchemical session name from independent 16-element lists.
# Each call returns a fresh name — capture once per shell if you need stability.
# Two 16-element lists give 256 combinations; occasional collisions are tolerable
# since zellij attach --create no-ops on an already-running same-name session.
_potions_zellij_session_name() {
  local _materials=(golden silver copper iron obsidian azure crimson verdant pale molten
                    frozen ethereal arcane vivid tarnished radiant)
  local _alchemical_words=(cauldron elixir alembic crucible tincture phlogiston azoth vitriol
                           philosopher quintessence transmutation reagent catalyst retort sublimate athanor)
  local w1=$(( (RANDOM % 16) + 1 ))
  local w2=$(( (RANDOM % 16) + 1 ))
  echo "${_materials[$w1]}-${_alchemical_words[$w2]}"
}

# Names passed to Zellij. Empty, flag-like, or punctuation-bearing values are refused.
_potions_session_name_ok() {
  case "$1" in
    ""|-*|*[!A-Za-z0-9._-]*) return 1 ;;
  esac
  [ "${#1}" -le 64 ]
}

# Resume rejoins a mood that is already alive. It does not mint a name.
# A second client is refused by Zellij. Do not pass --force: that mirrors
# the terminal that is still open.
_potions_resume_mood() {
  local name="$1"
  _potions_session_name_ok "$name" || return 0
  command zellij --config-dir "$POTIONS_HOME/zellij" attach "$name"
}

# Begin is the only path that mints. A valid POTIONS_SESSION pin is used as-is.
# attach --create resurrects that mood when it is not already alive.
_potions_begin_mood() {
  local name=""
  if [ -n "${POTIONS_SESSION:-}" ] && _potions_session_name_ok "$POTIONS_SESSION"; then
    name="$POTIONS_SESSION"
  else
    name="$(_potions_zellij_session_name)"
  fi
  _potions_session_name_ok "$name" || return 0
  command zellij --config-dir "$POTIONS_HOME/zellij" attach --create "$name" || true
}

# Personal interactive shells land on the door. AI editors keep a raw shell.
# Ctrl-C is the child's signal: this shell keeps going because the door is just
# a foreground command and the TRAPINT above refreshes the prompt.
_potions_personal_shell_should_enter_door() {
  [ -z "${ZELLIJ:-}" ] || return 1
  command -v zellij >/dev/null 2>&1 || return 1
  if is_ai_code_editor; then
    return 1
  fi
  case $- in
    *i*) ;;
    *) return 1 ;;
  esac
  [ -t 0 ] && [ -t 1 ] || return 1
  return 0
}

# Ctrl+a g opens this inset inside a session the caller already holds.
_potions_door_modal_run() {
  local session="$1"
  command zellij --config-dir "$POTIONS_HOME/zellij" --session "$session" run \
    --floating --close-on-exit --name Door \
    --x 10% --y 8% --width 80% --height 72% -- \
    "$POTIONS_HOME/bin/potions" door
}

_potions_living_mood() {
  POTIONS_HOME="${POTIONS_HOME:-$HOME/.potions}" command bash -c '
    # shellcheck disable=SC1091
    . "$POTIONS_HOME/lib/door.sh"
    potions_door_living_name
  '
}

# A new terminal rejoins a mood only when no other terminal holds it.
# Zellij exits with "Session attached to another client" rather than share
# the live window. That case opens the door here, and Resume stays explicit.
_potions_open_door() {
  local living="" attach_err
  living="$(_potions_living_mood)" || living=""
  if [ -n "$living" ] && _potions_session_name_ok "$living"; then
    attach_err="$(mktemp)"
    if command zellij --config-dir "$POTIONS_HOME/zellij" attach "$living" 2>"$attach_err"; then
      rm -f "$attach_err"
      return 0
    fi
    if grep -q "another client" "$attach_err" 2>/dev/null; then
      rm -f "$attach_err"
      command "$POTIONS_HOME/bin/potions" door || true
      return 0
    fi
    rm -f "$attach_err"
  fi
  # No mood yet. The lobby holds the modal. Begin still mints the name.
  command zellij --config-dir "$POTIONS_HOME/zellij" --session potions attach --create-background >/dev/null 2>&1 || true
  _potions_door_modal_run potions >/dev/null 2>&1 || true
  command zellij --config-dir "$POTIONS_HOME/zellij" attach potions || true
}

if _potions_personal_shell_should_enter_door; then
  _potions_open_door
fi
