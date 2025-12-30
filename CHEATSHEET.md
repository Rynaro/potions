# 🧪 Potions Cheatsheet

Quick reference guide for all keybindings and shortcuts in Potions development environment.

> **Note**: All keybindings are macOS-friendly and optimized for terminal coding workflows.

---

## 📋 Table of Contents

- [Tmux](#tmux-keybindings)
- [Neovim](#neovim-keybindings)
- [Quick Tips](#quick-tips)
- [macOS-Specific Notes](#macos-specific-notes)
- [Reloading Configurations](#reloading-configurations)
- [Emergency Commands](#emergency-commands)

---

## Tmux Keybindings

### Basic Information
- **Prefix Key**: `Ctrl+a` (instead of default `Ctrl+b`)
- **Windows start at**: 1 (not 0)
- **Mouse support**: Enabled

### Session Management
| Keybinding | Action |
|------------|--------|
| `Ctrl+a S` | List and switch sessions |
| `Ctrl+a (`, `Ctrl+a )` | Switch to previous/next session |
| `tmux new -s name` | Create new named session |
| `tmux attach -t name` | Attach to named session |
| `tmux list-sessions` | List all sessions |

### Window Management
| Keybinding | Action |
|------------|--------|
| `Ctrl+a c` | Create new window |
| `Ctrl+a X` | Close current window |
| `Ctrl+a x` | Close current pane |
| `Ctrl+a s` or `Ctrl+a w` | List and switch windows |
| `Ctrl+Tab` | Next window (no prefix needed) |
| `Ctrl+Shift+Tab` | Previous window (no prefix needed) |
| `Ctrl+a n` | Next window (with prefix) |
| `Ctrl+a p` | Previous window (with prefix) |
| `Ctrl+a R` | Rename current window |
| `Ctrl+a ,` | Rename window (with prompt) |

> **Note**: `Ctrl+n` and `Ctrl+p` without prefix were removed to avoid conflicts with shell history and Neovim.

### Pane Management
| Keybinding | Action |
|------------|--------|
| `Ctrl+a \|` | Split pane horizontally |
| `Ctrl+a -` | Split pane vertically |
| `Ctrl+a h/j/k/l` | Navigate panes (vim-style) |
| `Ctrl+a x` | Close current pane |
| `Ctrl+a B` | Break pane into new window |
| `Ctrl+a J` | Join pane from another window |
| `Ctrl+a <` | Swap pane up |
| `Ctrl+a >` | Swap pane down |

### Pane Resizing
| Keybinding | Action |
|------------|--------|
| `Ctrl+a Ctrl+h/j/k/l` | Resize pane (vim-style) |
| `Ctrl+a Ctrl+Arrow` | Resize pane (arrow keys) |
| Hold key for repeat | Continuous resizing |

### Layout Management
| Keybinding | Action |
|------------|--------|
| `Ctrl+a =` | Even horizontal layout |
| `Ctrl+a E` | Even vertical layout |
| `Ctrl+a T` | Tiled layout |
| `Ctrl+a M` | Main horizontal layout |
| `Ctrl+a V` | Main vertical layout |

### Configuration
| Keybinding | Action |
|------------|--------|
| `Ctrl+a r` | Reload tmux config |

---

## Neovim Keybindings

### Basic Information
- **Leader Key**: `Space` (more ergonomic than default `\`)
- **File Management**: NERDTree file explorer
- **Buffer Management**: Barbar plugin
- **Search**: Telescope fuzzy finder

### File Management
| Keybinding | Action |
|------------|--------|
| `Ctrl+n` | Toggle NERDTree |
| `Space nf` | Find current file in NERDTree |
| `Space ff` | Find files (Telescope) |
| `Space fg` | Live grep (Telescope) |
| `Space fb` | Find buffers (Telescope) |
| `Space fh` | Help tags (Telescope) |
| `Space fs` | Git status (Telescope) |
| `Space fc` | Git commits (Telescope) |
| `Space fr` | LSP references (Telescope) |
| `Space fd` | LSP definitions (Telescope) |

### File Paths
| Keybinding | Action |
|------------|--------|
| `Space yr` | Copy relative file path |
| `Space ya` | Copy absolute file path |

### Saving & Quitting
| Keybinding | Action |
|------------|--------|
| `Ctrl+s` | Quick save (works in all modes) |
| `Space w` | Write (save) file |
| `Space q` | Quit |
| `Space Q` | Quit without saving |
| `Space wq` | Write and quit |

### Navigation
| Keybinding | Action |
|------------|--------|
| `Ctrl+a` | Move to beginning of line |
| `Ctrl+e` | Move to end of line |
| `Ctrl+{` | Previous paragraph |
| `Ctrl+}` | Next paragraph |
| `Ctrl+u` | Move up 10 lines |
| `Ctrl+d` | Move down 10 lines |
| `Space gg` | Go to top of file |
| `Space G` | Go to bottom of file |

### Search
| Keybinding | Action |
|------------|--------|
| `/` | Search forward |
| `?` | Search backward |
| `n` | Next match |
| `N` | Previous match |
| `Space /` | Search word under cursor |
| `Space Space` | Clear search highlight |

### Editing
| Keybinding | Action |
|------------|--------|
| `Ctrl+c` | Copy (visual mode) |
| `Ctrl+x` | Cut (visual mode) |
| `Ctrl+v` | Paste |
| `Shift+Tab` | Unindent (insert mode) |
| `Space a` | Select all |

### Moving Lines
| Keybinding | Action |
|------------|--------|
| `Ctrl+Shift+Up` | Move line up |
| `Ctrl+Shift+Down` | Move line down |
| `Ctrl+k` | Move line up (alternative) |
| `Ctrl+j` | Move line down (alternative) |

### Buffer Management
| Keybinding | Action |
|------------|--------|
| `Ctrl+Shift+h` | Previous buffer |
| `Ctrl+Shift+l` | Next buffer |
| `Ctrl+Shift+H` | Move buffer left |
| `Ctrl+Shift+L` | Move buffer right |
| `Space 1-9` | Go to buffer number |
| `Space 0` | Go to last buffer |
| `Space bp` | Pick buffer (buffer picker) |
| `Space bx` | Pick and delete buffer |
| `Space bi` | Pin buffer |
| `Space bc` | Close buffer |
| `Space br` | Restore buffer |
| `Space bb` | Order by buffer number |
| `Space bn` | Order by name |
| `Space bd` | Order by directory |
| `Space bl` | Order by language |
| `Space bw` | Order by window number |

### Multi-Cursor Editing (VSCode-like)
| Keybinding | Action |
|------------|--------|
| `Space d` | Find/select next occurrence |
| `Ctrl+Shift+l` | Select all occurrences |
| `Space x` | Skip current occurrence |
| `Ctrl+Shift+k` | Remove current cursor |
| `Ctrl+Shift+Down` | Add cursor below |
| `Ctrl+Shift+Up` | Add cursor above |

> **Note**: Multi-cursor start changed from `Ctrl+d` to `Space d` to avoid conflict with scroll.

### Treesitter Navigation
| Keybinding | Action |
|------------|--------|
| `gnn` | Init selection |
| `grn` | Incremental selection |
| `grc` | Scope incremental |
| `grm` | Decremental selection |
| `af` | Select outer function |
| `if` | Select inner function |
| `]m` | Next function |
| `[m` | Previous function |

---

## Quick Tips

### Tmux Tips
1. **Quick window switching**: Use `Ctrl+Tab` / `Ctrl+Shift+Tab` for browser-like tab switching
2. **Pane navigation**: Vim-style `h/j/k/l` after prefix key
3. **Reload config**: `Ctrl+a r` to reload without restarting
4. **Mouse support**: Click to select panes, drag to resize

### Neovim Tips
1. **Leader key**: Most commands start with `Space`
2. **Quick save**: `Ctrl+s` works in all modes
3. **Buffer navigation**: Use `Ctrl+Shift+h/l` for easy buffer switching
4. **File finding**: `Space ff` for instant file search
5. **Multi-cursor**: `Ctrl+d` to find next occurrence, VSCode-style

### Workflow Tips
1. **Split workflow**: 
   - Open tmux → Split panes → Open files in nvim
   - Use telescope to find files quickly
   - Navigate buffers without closing files

2. **Code navigation**:
   - Use treesitter `]m` / `[m` to jump between functions
   - Use `Space fd` for LSP definitions
   - Use `Space fr` for references

3. **Multi-file editing**:
   - Open multiple buffers with `Space ff`
   - Switch with `Ctrl+Shift+h/l`
   - Use `Space 1-9` for quick buffer access

---

## macOS-Specific Notes

All keybindings are optimized for macOS:

- ✅ **No Alt/Option conflicts**: Uses Ctrl+Shift combinations instead
- ✅ **Terminal-friendly**: Works in Terminal.app, iTerm2, and other terminals
- ✅ **System shortcut compatible**: Avoids conflicts with macOS system shortcuts
- ✅ **Ergonomic**: Leader key set to Space bar for easier access

---

## Reloading Configurations

### Tmux
```bash
# Inside tmux
Ctrl+a r

# Or restart tmux session
exit  # to exit tmux
tmux  # to start new session
```

### Neovim
```bash
# Inside neovim
:source ~/.config/nvim/init.vim

# Or restart neovim
# Changes take effect on next start
```

---

## Emergency Commands

### Essential Vim Commands
When you're stuck or need quick actions:

| Command | Action |
|---------|--------|
| `:w` | Save file |
| `:q` | Quit (fails if unsaved) |
| `:q!` | Quit without saving (force quit) |
| `:wq` | Save and quit |
| `:x` | Save and quit (same as `:wq`) |
| `:e!` | Reload file (discard changes) |
| `:BufferCloseAllButCurrent` | Close all buffers except current |
| `:set number` | Show line numbers |
| `:set nonumber` | Hide line numbers |
| `:help <topic>` | Get help on topic |

### Emergency Navigation
- `Esc` - Exit insert/visual mode (press multiple times if stuck)
- `u` - Undo
- `Ctrl+r` - Redo
- `Ctrl+c` - Cancel current operation
- `gg` - Go to top of file
- `G` - Go to bottom of file

---

## If a Keybinding Doesn't Work

### Check Terminal Support

Some key combinations require terminal configuration:

| Key | Issue | Solution |
|-----|-------|----------|
| `Ctrl+Tab` | Not sent by terminal | Use `Ctrl+a n` instead, or configure terminal |
| `Ctrl+Arrow` | Wrong sequence | Try `Alt+f`/`Alt+b` for word navigation |
| `Ctrl+Shift+*` | Intercepted by OS | Check System Preferences / terminal settings |

### Terminal-Specific Notes

**iTerm2**: Best compatibility. Configure Left Option as "Esc+" for Alt combinations.

**Terminal.app**: Limited key support. Use `Ctrl+a n`/`Ctrl+a p` for window navigation.

**VS Code/Cursor**: Some keys intercepted by editor. Check keyboard shortcuts settings.

### Debug Key Sequences

```bash
# See what escape sequence your terminal sends
cat -v
# Press your key combination, then Ctrl+C
```

### More Help

- See [KEYMAPS.md](.potions/KEYMAPS.md) for complete keymap reference
- See [Terminal Setup](.potions/terminal-setup/TERMINAL_SETUP.md) for terminal configuration

---

**Last Updated**: Based on Potions configuration optimized for macOS terminal workflows.
