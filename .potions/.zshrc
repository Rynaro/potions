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
  grep -qi microsoft /proc/version
}

# Function to check if the environment is macOS
is_macos() {
  [ "$(uname -s)" = "Darwin" ]
}

# Function to check if running in an AI code editor terminal (VSCode, Cursor, etc.)
# These terminals should not auto-start tmux to avoid terminal output capture issues
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
PROMPT='%F{cyan}%n%f%F{magenta}@%f%F{red}%m%f:%b$(git_super_status 2>/dev/null || echo "") %~ %(#.#.$) '

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
    bindkey "^[[5C" forward-word    # Alternative (tmux)
    bindkey "^[[5D" backward-word   # Alternative (tmux)
    bindkey "^[f" forward-word      # Alt+f fallback
    bindkey "^[b" backward-word     # Alt+b fallback
    ;;
esac

# Common bindings that work across all terminals
bindkey "^[[5C" forward-word    # Alternative sequence (tmux passthrough)
bindkey "^[[5D" backward-word   # Alternative sequence (tmux passthrough)

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

# Auto-start tmux only if not already in tmux and not in an AI code editor terminal
# AI code editors (VSCode, Cursor, etc.) should not auto-start tmux to avoid
# terminal output capture issues
if command -v tmux &> /dev/null && [ -z "$TMUX" ] && ! is_ai_code_editor; then
  TMUX_PROFILE_NAME="potions-$$+"
  tmux -f $POTIONS_HOME/tmux/tmux.conf new-session -s "$TMUX_PROFILE_NAME"
fi
