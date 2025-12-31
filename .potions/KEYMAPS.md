# Potions Keymaps Reference

This document provides a unified reference for all keybindings across Zsh, Tmux, and Neovim to help understand and avoid conflicts.

---

## Quick Reference Table

| Key Combo | Zsh | Tmux | Neovim | Notes |
|-----------|-----|------|--------|-------|
| `Ctrl+a` | - | PREFIX | Beginning of line | Neovim uses for line navigation |
| `Ctrl+b` | - | (unbound) | - | Available |
| `Ctrl+c` | Interrupt | - | Copy (visual) | Standard interrupt in shell |
| `Ctrl+d` | EOF/Logout | - | Move 10 lines down | Be careful in shell |
| `Ctrl+e` | - | - | End of line | |
| `Ctrl+h/j/k/l` | - | Resize panes | Move lines | After Tmux prefix |
| `Ctrl+n` | History next | - | NERDTree toggle | **Conflict resolved: removed from tmux** |
| `Ctrl+p` | History prev | - | Buffer pick → `<leader>bp` | **Changed to avoid conflict** |
| `Ctrl+s` | - | - | Quick save | Enable with `stty -ixon` |
| `Ctrl+u` | Clear line | - | Move 10 lines up | |
| `Ctrl+v` | - | - | Paste | |
| `Ctrl+x` | - | - | Buffer pick delete → `<leader>bx` | **Changed to avoid conflict** |
| `Ctrl+Tab` | - | Next window | - | May not work in all terminals |
| `Ctrl+Shift+Tab` | - | Prev window | - | May not work in all terminals |
| `Ctrl+Arrow` | Word nav | Resize panes | - | Terminal-dependent |
| `Space` | - | - | LEADER | Most Neovim commands |

---

## Reserved Keys by Tool

### Tmux Reserved Keys (with prefix `Ctrl+a`)

These keys are used after pressing `Ctrl+a`:

| Key | Action |
|-----|--------|
| `c` | New window |
| `x` | Kill pane |
| `X` | Kill window |
| `h/j/k/l` | Navigate panes |
| `C-h/j/k/l` | Resize panes |
| `\|` | Split horizontal |
| `-` | Split vertical |
| `=` | Even horizontal layout |
| `E` | Even vertical layout |
| `T` | Tiled layout |
| `M` | Main horizontal layout |
| `V` | Main vertical layout |
| `S` | Choose session |
| `s` / `w` | Choose window |
| `r` | Reload config |
| `B` | Break pane |
| `J` | Join pane |
| `R` | Rename window |
| `<` / `>` | Swap pane left/right |

**No-prefix bindings** (work without `Ctrl+a`):

| Key | Action |
|-----|--------|
| `Ctrl+Tab` | Next window |
| `Ctrl+Shift+Tab` | Previous window |

### Neovim Reserved Keys

**Leader-based commands** (press `Space` first):

| Key | Action |
|-----|--------|
| `ff` | Find files (Telescope) |
| `fg` | Live grep |
| `fb` | Find buffers |
| `fh` | Help tags |
| `fs` | Git status |
| `fc` | Git commits |
| `fr` | LSP references |
| `fd` | LSP definitions |
| `nf` | NERDTree find |
| `yr` | Copy relative path |
| `ya` | Copy absolute path |
| `gg` | Go to top |
| `G` | Go to bottom |
| `Space` | Clear search highlight |
| `/` | Search word under cursor |
| `a` | Select all |
| `q` | Quit |
| `Q` | Quit! |
| `w` | Write |
| `wq` | Write and quit |
| `1-9` | Go to buffer N |
| `0` | Go to last buffer |
| `bp` | Buffer pick (moved from Ctrl+p) |
| `bx` | Buffer pick delete (moved from Ctrl+x) |
| `bc` | Buffer close |
| `br` | Buffer restore |
| `bb/bn/bd/bl/bw` | Buffer ordering |
| `d` | Start multi-cursor (moved from Ctrl+d) |

**Ctrl-based commands**:

| Key | Action |
|-----|--------|
| `Ctrl+n` | Toggle NERDTree |
| `Ctrl+a` | Beginning of line |
| `Ctrl+e` | End of line |
| `Ctrl+u` | Move up 10 lines |
| `Ctrl+d` | Move down 10 lines |
| `Ctrl+c` | Copy (visual mode) |
| `Ctrl+v` | Paste |
| `Ctrl+s` | Quick save |
| `Ctrl+k/j` | Move line up/down |
| `Ctrl+Shift+h/l` | Prev/next buffer |
| `Ctrl+Shift+H/L` | Move buffer left/right |
| `Ctrl+Shift+Up/Down` | Move line up/down |

### Zsh Reserved Keys

| Key | Action |
|-----|--------|
| `Ctrl+a` | Beginning of line (readline) |
| `Ctrl+e` | End of line (readline) |
| `Ctrl+u` | Clear line to start |
| `Ctrl+k` | Clear line to end |
| `Ctrl+w` | Delete word backward |
| `Ctrl+r` | Reverse search history |
| `Ctrl+p` | Previous history |
| `Ctrl+n` | Next history |
| `Ctrl+c` | Interrupt (SIGINT) |
| `Ctrl+d` | EOF / Logout |
| `Ctrl+l` | Clear screen |
| `Ctrl+Right` | Forward word |
| `Ctrl+Left` | Backward word |

---

## Conflict-Free Zones

### Keys Safe to Use Everywhere

These keys have no conflicts and are safe to bind:

- `F1-F12` function keys
- `Alt+` combinations (but may conflict with macOS)
- Most `Ctrl+Shift+` combinations
- All `Leader+` combinations in Neovim

### Terminal-Specific Escape Sequences

Different terminals send different escape sequences for the same key combination:

#### Word Navigation (`Ctrl+Arrow`)

| Terminal | Right Arrow | Left Arrow |
|----------|-------------|------------|
| iTerm2 | `^[[1;5C` | `^[[1;5D` |
| Terminal.app | `^[f` (Alt+f) | `^[b` (Alt+b) |
| Alacritty | `^[[1;5C` | `^[[1;5D` |
| tmux | `^[[5C` | `^[[5D` |
| VS Code Terminal | `^[[1;5C` | `^[[1;5D` |

The `.zshrc` configuration includes bindings for all common terminals.

---

## Known Conflicts and Resolutions

### Resolved Conflicts

| Conflict | Old Binding | Resolution |
|----------|-------------|------------|
| `Ctrl+n` - Tmux window nav vs NERDTree | Tmux: `C-n` | **Removed from Tmux** - use `Ctrl+Tab` instead |
| `Ctrl+p` - Tmux window nav vs Buffer pick | Tmux: `C-p` | **Removed from Tmux** - use `Ctrl+Shift+Tab`; Neovim: use `<leader>bp` |
| `Ctrl+x` - Buffer delete vs multi-cursor skip | Both Neovim | **Neovim changed** to `<leader>bx` for buffer delete |
| `Ctrl+d` - Multi-cursor vs scroll | Both Neovim | **Multi-cursor changed** to `<leader>d` |

### Potential Conflicts (User Awareness)

| Keys | Conflict | Mitigation |
|------|----------|------------|
| `Ctrl+a` | Tmux prefix vs Neovim line start | In Neovim inside Tmux, press `Ctrl+a` twice to send to Neovim |
| `Ctrl+d` | Shell EOF vs Neovim scroll | Be careful at command line; in Neovim it scrolls |

---

## Terminal Configuration

For optimal key binding support, configure your terminal:

### iTerm2

1. Go to Preferences → Profiles → Keys
2. Set "Left Option Key" to "Esc+" for Alt combinations
3. Add key mappings:
   - `Ctrl+Tab` → Send Escape Sequence: `[27;5;9~`
   - `Ctrl+Shift+Tab` → Send Escape Sequence: `[27;6;9~`

### Terminal.app

Terminal.app has limited key support. Consider:
- Using Alt+f/Alt+b for word navigation (enabled by default)
- Switching to iTerm2 for full key support

### Alacritty

Add to your `alacritty.yml`:

```yaml
key_bindings:
  - { key: Tab, mods: Control, chars: "\x1b[27;5;9~" }
  - { key: Tab, mods: Control|Shift, chars: "\x1b[27;6;9~" }
```

---

## Customization

### Adding Custom Bindings

**Neovim**: Add to `~/.potions/nvim/user.vim` (preserved on upgrade)

**Tmux**: Add to `~/.potions/tmux/user.conf` (preserved on upgrade)

**Zsh**: Add to `~/.potions/config/aliases.zsh` (preserved on upgrade)

### Overriding Default Bindings

To override a default binding, add your custom binding in the user files above. User configurations are loaded after default configurations.

---

## Troubleshooting

### Key Not Working

1. **Check terminal support**: Some terminals don't send certain key sequences
2. **Check for conflicts**: Use `cat -v` or `showkey -a` to see what your terminal sends
3. **Check tmux passthrough**: Ensure tmux isn't intercepting the key

### Testing Key Sequences

```bash
# In terminal, press Ctrl+V then your key combo to see the escape sequence
# Or use:
cat -v
# Then press your key combo and see what's printed
```

### Debugging in Neovim

```vim
" See what key was pressed
:verbose map <your-key>

" Check if key is mapped
:map
```

### Debugging in Tmux

```bash
# Show all key bindings
tmux list-keys

# Show bindings for specific key
tmux list-keys | grep <key>
```
