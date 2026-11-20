#!/bin/bash

# The renderer reads the detected capabilities after sourcing this library.
# shellcheck disable=SC2034
detect_terminal_capabilities() {
  POTIONS_HAS_COLOR=false
  if [ -t 1 ] && [ -z "${NO_COLOR:-}" ] && [ "${TERM:-dumb}" != dumb ]; then
    POTIONS_HAS_COLOR=true
  fi

  POTIONS_HAS_UNICODE=false
  local charmap
  charmap=$(locale charmap 2>/dev/null) || charmap="${LC_ALL:-${LC_CTYPE:-${LANG:-C}}}"
  case "$charmap" in
    *[Uu][Tt][Ff]-8*|*[Uu][Tt][Ff]8*) POTIONS_HAS_UNICODE=true ;;
  esac
}

# The desk and the printable reference share this tab-separated shortcut catalog.
desk_shortcuts() {
  cat <<'SHORTCUTS'
Zellij	Ctrl+a Space	Open Potions Desk
Zellij	Ctrl+a	Enter prefix mode
Zellij	F1 / Ctrl+a ?	Open the searchable shortcut browser
Zellij	Alt+/	Open the shortcut browser (macOS requires Option as Meta)
Zellij	Alt+h/j/k/l	Focus the pane to the left, below, above or right
Zellij	Alt+arrows	Focus the pane in that direction
Zellij	Alt+d	Split pane right
Zellij	Alt+t	New tab
Zellij	Alt+w	Close pane
Zellij	Alt+n / Alt+p	Next or previous tab
Zellij	Alt+Enter	Toggle fullscreen
Zellij	Ctrl+Tab / Ctrl+Shift+Tab	Next or previous tab if your terminal forwards the keys
Zellij	Ctrl+a |	Split pane right
Zellij	Ctrl+a -	Split pane down
Zellij	Ctrl+a c	New tab
Zellij	Ctrl+a x	Close pane
Zellij	Ctrl+a X	Close tab
Zellij	Ctrl+a n / p	Next or previous tab
Zellij	Ctrl+a 1-9	Focus a numbered tab
Zellij	Ctrl+a h/j/k/l	Navigate panes
Zellij	Ctrl+a r	Resize with h/j/k/l or H/J/K/L, then Enter to finish
Zellij	Ctrl+a Ctrl+h/j/k/l	Resize the pane in that direction
Zellij	Ctrl+a =	Cycle pane layouts
Zellij	Ctrl+a < / >	Swap panes backward or forward
Zellij	Ctrl+a { / }	Move the pane left or right
Zellij	Ctrl+a z	Toggle fullscreen
Zellij	Ctrl+a f	Float or embed the focused pane
Zellij	Ctrl+a F	Show or hide floating panes
Zellij	Ctrl+a B	Move the focused pane into its own tab
Zellij	Ctrl+a R	Rename the current tab
Zellij	Ctrl+a S w	Open the session manager
Zellij	Ctrl+a S d	Detach from this session
Zellij	Ctrl+a Ctrl+a	Send Ctrl+a to the focused application
Zsh	Ctrl+a	Beginning of line (inside Zellij, press Ctrl+a twice)
Zsh	Ctrl+e	End of line
Zsh	Ctrl+u	Clear from cursor to start of line
Zsh	Ctrl+k	Clear from cursor to end of line
Zsh	Ctrl+w	Delete word backward
Zsh	Ctrl+l	Clear screen
Zsh	Ctrl+r	Reverse history search
Zsh	Ctrl+p / Ctrl+n	Previous or next history entry
Zsh	Ctrl+c	Interrupt the running command
Zsh	Ctrl+d	End of input on an empty prompt outside Zellij
Neovim	Space ?	Open or close the Neovim cheatsheet
Neovim	Ctrl+s	Save file
Neovim	Ctrl+n	Toggle NERDTree file explorer
Neovim	Ctrl+c	Copy visual selection to clipboard
Neovim	Ctrl+v	Paste from clipboard
Neovim	Space ff	Find files with Telescope
Neovim	Space fg	Live grep with Telescope
Neovim	Space fb	List open buffers
Neovim	Space fs	Find changed Git files
Neovim	Space fc	Browse Git commits
Neovim	Space fh	Find help tags
Neovim	Space q	Quit
Neovim	Space wq	Write and quit
Neovim	Space w	Save file
Neovim	Space h/l	Previous or next buffer
Neovim	Space 1-9	Focus a numbered buffer
Neovim	Space 0	Focus the last buffer
Neovim	Tab / Shift+Tab	Next or previous buffer in normal mode
Neovim	Space H/L	Move the current buffer left or right
Neovim	Space bp	Pick a buffer
Neovim	Space bx	Pick a buffer to close
Neovim	Space bi	Toggle pin on the current buffer
Neovim	Space bc	Close the current buffer
Neovim	Space br	Restore the last closed buffer
Neovim	Space bo	Close all other buffers
Neovim	Space bP	Close all unpinned buffers
Neovim	Space b[ / b]	Close buffers to the left or right
Neovim	Space nf	Reveal current file in NERDTree
Neovim	Space /	Search word under cursor
Neovim	Space j/k	Move selected lines down or up
Neovim	Space d	Add a cursor on the current word
SHORTCUTS
}

print_shortcuts() {
  desk_shortcuts | awk -F '\t' '
    $1 != section { section = $1; printf "\n%s\n", section }
    { printf "  %-20s  %s\n", $2, $3 }
  '
}
