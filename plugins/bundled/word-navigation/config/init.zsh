# Preserve the default word bindings at their original place in managed startup.
_potions_word_navigation_apply() {
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
}

if [ "${_POTIONS_DEFER_PLUGIN_SETUP:-}" = 1 ]; then
  _POTIONS_LATE_PLUGIN_INIT+=(_potions_word_navigation_apply)
else
  _potions_word_navigation_apply
fi
