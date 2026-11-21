POTIONS_HOME="${POTIONS_HOME:-$HOME/.potions}"

# Zellij emulates xterm-256color. Panes inherit the outer TERM (xterm-ghostty,
# xterm-kitty, alacritty, wezterm). SSH then forwards that name, and the remote
# emits scroll-region, charset, and synchronized-output sequences Zellij does
# not emulate. Scrolling repaints the desynced grid and characters overlap.
# Pin the pane before the prompt or any SSH so local editing and remote
# programs both speak the TERM Zellij actually implements. A bare Ghostty
# (no Zellij) keeps xterm-ghostty so ssh-terminfo can still install it.
if [ -n "$ZELLIJ" ]; then
  case "${TERM:-}" in
    xterm-256color|screen-256color|tmux-256color|xterm-color) ;;
    *) export TERM=xterm-256color ;;
  esac
fi

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
export EDITOR="${EDITOR:-nvim}"

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
_POTIONS_DEFER_PLUGIN_SETUP=1
_POTIONS_LATE_PLUGIN_INIT=()
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

# Apply deferred plugin setup after platform customizations, preserving defaults.
unset _POTIONS_DEFER_PLUGIN_SETUP
for _potions_setup in "${_POTIONS_LATE_PLUGIN_INIT[@]}"; do
  "$_potions_setup"
done
unset _POTIONS_LATE_PLUGIN_INIT _potions_setup

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

# Return the pane to a known state after SSH. A remote TUI can leave mouse
# tracking or the line-drawing charset armed; the next scroll then repaints
# with mixed glyphs. The alternate screen is left alone — Zellij lives there.
_potions_terminal_restore() {
  [ -t 1 ] || return 0
  printf '\033[?1000l\033[?1002l\033[?1003l\033[?1006l\033[?1015l\033[?1004l\033[?2004l\033[0m\033(B\017'
}

# One wrap per shell. Inside Zellij, also stop Ghostty's ssh wrapper (when it
# is present) from advertising xterm-ghostty: --terminfo=false makes `ghostty
# +ssh` fall back to xterm-256color, which matches the pane pin above.
if [[ -o interactive ]] && [ -z "${_POTIONS_SSH_WRAPPED:-}" ]; then
  _POTIONS_SSH_WRAPPED=1
  if (( $+functions[ssh] )); then
    functions -c ssh _potions_ssh_impl
  else
    _potions_ssh_impl() { command ssh "$@"; }
  fi
  ssh() {
    local _st
    if [ -n "${ZELLIJ:-}" ]; then
      local GHOSTTY_SHELL_FEATURES="${GHOSTTY_SHELL_FEATURES//ssh-terminfo/}"
      TERM=xterm-256color _potions_ssh_impl "$@"
    else
      _potions_ssh_impl "$@"
    fi
    _st=$?
    _potions_terminal_restore
    return "$_st"
  }
fi

# Auto-start zellij only if not already in zellij and not in an AI code editor terminal
# AI code editors (VSCode, Cursor, etc.) should not auto-start zellij to avoid
# terminal output capture issues
if [[ -o interactive && -t 0 && -t 1 && -z "$ZELLIJ" ]] && command -v zellij &> /dev/null && ! is_ai_code_editor; then
  _potions_session="${POTIONS_SESSION:-$(_potions_zellij_session_name)}"
  command zellij --config-dir "$POTIONS_HOME/zellij" attach --create "$_potions_session"
fi
