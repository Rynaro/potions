OS_TYPE="$(uname -s)"

# Function to safely source a file if it exists
safe_source() {
  [ -f "$1" ] && source "$1"
}

# Load antidote plugin manager
safe_source "${ZDOTDIR:-$HOME}/.antidote/antidote.zsh"
if command -v antidote &> /dev/null; then
  antidote load
fi

# Neovim as the default editor
export EDITOR=nvim

# Docker completion
if [ -f "/usr/share/zsh/vendor-completions/_docker" ]; then
  fpath=("/usr/share/zsh/vendor-completions" $fpath)
fi

# Git Prompt configuration
PROMPT='%F{cyan}%n%f%F{magenta}@%f%F{red}%m%f:%b$(git_super_status) %~ %(#.#.$) '

case "$OS_TYPE" in
  Darwin)
    # macOS-specific configurations
    export PATH="/opt/homebrew/bin:/opt/homebrew/opt/libpq/bin:$(brew --prefix openvpn)/sbin:$PATH"
    eval "$(rbenv init - zsh)"
    export NVM_DIR="$HOME/.nvm"
    safe_source "$(brew --prefix nvm)/nvm.sh"
    safe_source "/Users/henrique/.docker/init-zsh.sh"
    ;;
  Linux)
    # WSL-specific configurations
    if grep -qi microsoft /proc/version; then
      export PATH="$HOME/.rbenv/bin:$PATH"
      eval "$(rbenv init - zsh)"
      export NVM_DIR="$HOME/.nvm"
      safe_source "$NVM_DIR/nvm.sh"
    fi
    ;;
  Android)
    # Termux-specific configurations
    export PATH="$HOME/.rbenv/bin:$PATH"
    eval "$(rbenv init - zsh)"
    export NVM_DIR="$HOME/.nvm"
    safe_source "$NVM_DIR/nvm.sh"
    ;;
esac

# Initialize command completion
autoload -Uz compinit && compinit

safe_source "${ZDOTDIR:-$HOME}/.zsh_aliases"
safe_source "${ZDOTDIR:-$HOME}/.zsh_secure_aliases"
