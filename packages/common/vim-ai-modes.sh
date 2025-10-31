#!/bin/bash

# Install vim-ai-modes: wrapper scripts for vim-cursor and vim-copilot
# These scripts create a tmux session with a sidepanel for AI assistants

ensure_directory "$POTIONS_HOME/bin"

# Create vim-cursor wrapper script
cat > "$POTIONS_HOME/bin/vim-cursor" << 'VIM_CURSOR_EOF'
#!/bin/bash

# vim-cursor: Open vim with Cursor AI assistant in tmux sidepanel
# Usage: vim-cursor [vim-args...]

SIDE_PANEL_WIDTH=30  # Percentage width for sidepanel
SESSION_NAME="vim-cursor-$$"
AI_CMD="cursor-agent"  # Change to your cursor CLI command if different

# Check if tmux is available
if ! command -v tmux &> /dev/null; then
  echo "Error: tmux is not installed. Please install tmux first." >&2
  exec nvim "$@"
  exit $?
fi

# Check if cursor-agent is available
if ! command -v "$AI_CMD" &> /dev/null; then
  echo "Warning: $AI_CMD not found. Opening vim without sidepanel." >&2
  exec nvim "$@"
  exit $?
fi

# Create or attach to tmux session
if ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
  # Create new session with vim in main pane (properly quote arguments)
  if [ $# -eq 0 ]; then
    tmux new-session -d -s "$SESSION_NAME" -x 200 -y 50 nvim
  else
    # Use sh -c to properly handle all arguments
    tmux new-session -d -s "$SESSION_NAME" -x 200 -y 50 sh -c "nvim $(printf '%q ' "$@")"
  fi
  
  # Split window vertically, resize to create sidepanel
  tmux split-window -h -t "$SESSION_NAME"
  tmux resize-pane -t "$SESSION_NAME:0.1" -x "$SIDE_PANEL_WIDTH%"
  
  # Run AI assistant in sidepanel
  tmux send-keys -t "$SESSION_NAME:0.1" "$AI_CMD" C-m
  
  # Focus main pane (vim)
  tmux select-pane -t "$SESSION_NAME:0.0"
  
  # Attach to session interactively
  tmux attach-session -t "$SESSION_NAME"
else
  # Session exists, attach to it
  tmux attach-session -t "$SESSION_NAME"
fi
VIM_CURSOR_EOF

# Create vim-copilot wrapper script
cat > "$POTIONS_HOME/bin/vim-copilot" << 'VIM_COPILOT_EOF'
#!/bin/bash

# vim-copilot: Open vim with GitHub Copilot CLI in tmux sidepanel
# Usage: vim-copilot [vim-args...]

SIDE_PANEL_WIDTH=30  # Percentage width for sidepanel
SESSION_NAME="vim-copilot-$$"
AI_CMD="github-copilot-cli"  # Change to your copilot CLI command if different

# Check if tmux is available
if ! command -v tmux &> /dev/null; then
  echo "Error: tmux is not installed. Please install tmux first." >&2
  exec nvim "$@"
  exit $?
fi

# Check if copilot CLI is available
if ! command -v "$AI_CMD" &> /dev/null; then
  echo "Warning: $AI_CMD not found. Opening vim without sidepanel." >&2
  exec nvim "$@"
  exit $?
fi

# Create or attach to tmux session
if ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
  # Create new session with vim in main pane (properly quote arguments)
  if [ $# -eq 0 ]; then
    tmux new-session -d -s "$SESSION_NAME" -x 200 -y 50 nvim
  else
    # Use sh -c to properly handle all arguments
    tmux new-session -d -s "$SESSION_NAME" -x 200 -y 50 sh -c "nvim $(printf '%q ' "$@")"
  fi
  
  # Split window vertically, resize to create sidepanel
  tmux split-window -h -t "$SESSION_NAME"
  tmux resize-pane -t "$SESSION_NAME:0.1" -x "$SIDE_PANEL_WIDTH%"
  
  # Run AI assistant in sidepanel
  tmux send-keys -t "$SESSION_NAME:0.1" "$AI_CMD" C-m
  
  # Focus main pane (vim)
  tmux select-pane -t "$SESSION_NAME:0.0"
  
  # Attach to session interactively
  tmux attach-session -t "$SESSION_NAME"
else
  # Session exists, attach to it
  tmux attach-session -t "$SESSION_NAME"
fi
VIM_COPILOT_EOF

# Make scripts executable
chmod +x "$POTIONS_HOME/bin/vim-cursor"
chmod +x "$POTIONS_HOME/bin/vim-copilot"

log "vim-ai-modes installed: vim-cursor and vim-copilot commands are now available"
