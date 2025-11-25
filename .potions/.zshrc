POTIONS_HOME="$HOME/.potions"

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

safe_source "$POTIONS_HOME/.zsh_aliases"
safe_source "$POTIONS_HOME/.zsh_secure_aliases"

# Enable word navigation with Ctrl + arrow keys
bindkey "^[[1;5C" forward-word  # Ctrl + Right Arrow
bindkey "^[[1;5D" backward-word # Ctrl + Left Arrow
bindkey "^[[5C" forward-word    # Alternative sequence for Ctrl + Right Arrow
bindkey "^[[5D" backward-word   # Alternative sequence for Ctrl + Left Arrow

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

if command -v tmux &> /dev/null && [ -z "$TMUX" ]; then
  TMUX_PROFILE_NAME="potions-$$+"
  tmux -f $POTIONS_HOME/tmux/tmux.conf new-session -s "$TMUX_PROFILE_NAME"
fi
