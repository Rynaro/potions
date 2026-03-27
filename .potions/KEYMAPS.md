# Potions Keymaps Reference

This document provides a unified reference for all keybindings across Zsh, Zellij, and Neovim to help understand and avoid conflicts.

---

## Quick Reference Table

| Key Combo | Zsh | Zellij | Neovim | Notes |
|-----------|-----|--------|--------|-------|
| `Ctrl+a` | Beginning of line (readline) | PREFIX (enters tmux mode) | - (removed) | Zellij intercepts; use `0`/`^` in Neovim |
| `Ctrl+b` | - | (unbound) | - | Available |
| `Ctrl+c` | Interrupt | - | Copy (visual) | Standard interrupt in shell |
| `Ctrl+d` | EOF/Logout | - | - (removed override) | Vim default half-page down restored |
| `Ctrl+e` | - | - | - (removed) | Use `$` in Neovim |
| `Ctrl+n` | History next | - | NERDTree toggle | No conflict with zellij |
| `Ctrl+s` | - | - | Quick save | Enable with `stty -ixon` |
| `Ctrl+u` | Clear line | - | - (removed override) | Vim default half-page up restored |
| `Ctrl+v` | - | - | Paste | |
| `Ctrl+Tab` | - | Next tab | - | May not work in all terminals |
| `Ctrl+Shift+Tab` | - | Prev tab | - | May not work in all terminals |
| `Space` | - | - | LEADER | All Neovim commands |

---

## Reserved Keys by Tool

### Zellij Reserved Keys (with prefix `Ctrl+a`)

These keys are used after pressing `Ctrl+a` (enters tmux mode):

| Key | Action |
|-----|--------|
| `c` | New tab |
| `x` | Close pane |
| `X` | Close tab |
| `h/j/k/l` | Navigate panes |
| `C-h/j/k/l` | Resize panes (repeatable) |
| `\|` | Split right |
| `-` | Split down |
| `=` / `E` / `T` / `M` / `V` | Cycle layouts (NextSwapLayout) |
| `S` | Session manager |
| `B` | Break pane into tab |
| `R` | Rename tab |
| `<` / `>` | Swap pane position (repeatable) |
| `n` / `p` | Next / previous tab |
| `Ctrl+a` | Send Ctrl+a to application |

**No-prefix bindings** (work without `Ctrl+a`):

| Key | Action |
|-----|--------|
| `Ctrl+Tab` | Next tab |
| `Ctrl+Shift+Tab` | Previous tab |

---

## Neovim — Three-Tier Shortcut System

Neovim keybindings are organized into three tiers to maximize cross-platform reliability and avoid conflicts with Zellij and the shell.

### Tier 1 — Universal Ctrl (these always work)

These bindings use simple Ctrl combinations that are reliably passed through by all terminals and Zellij.

| Key | Mode | Action |
|-----|------|--------|
| `Ctrl+s` | Normal / Insert / Visual | Save file |
| `Ctrl+n` | Normal | Toggle NERDTree |
| `Ctrl+c` | Visual | Copy to system clipboard |
| `Ctrl+x` | Visual | Cut to system clipboard |
| `Ctrl+v` | Normal / Insert | Paste from system clipboard |

### Tier 2 — Leader (Space+key)

All navigation, buffer management, file operations, and editing commands. Press `Space` then the key.

#### File & NERDTree

| Key | Action |
|-----|--------|
| `Space` `nf` | NERDTree: reveal current file |
| `Space` `yr` | Copy relative file path to clipboard |
| `Space` `ya` | Copy absolute file path to clipboard |

#### Search

| Key | Action |
|-----|--------|
| `Space` `Space` | Clear search highlight |
| `Space` `/` | Search for word under cursor |

#### Quit / Write

| Key | Action |
|-----|--------|
| `Space` `q` | Quit |
| `Space` `Q` | Quit without saving |
| `Space` `w` | Write (save) |
| `Space` `wq` | Write and quit |

#### Buffer Navigation

| Key | Action |
|-----|--------|
| `Space` `h` | Previous buffer |
| `Space` `l` | Next buffer |
| `Space` `H` | Move buffer left |
| `Space` `L` | Move buffer right |
| `Tab` | Next buffer (normal mode) |
| `Shift+Tab` | Previous buffer (normal mode) |
| `Space` `1`–`9` | Go to buffer N |
| `Space` `0` | Go to last buffer |
| `Space` `bp` | Buffer pick (interactive) |
| `Space` `bx` | Buffer pick delete |
| `Space` `bi` | Pin buffer |
| `Space` `bc` | Close buffer |
| `Space` `br` | Restore buffer |
| `Space` `bb` | Order by buffer number |
| `Space` `bn` | Order by name |
| `Space` `bd` | Order by directory |
| `Space` `bl` | Order by language |
| `Space` `bw` | Order by window number |

#### Move Lines

| Key | Mode | Action |
|-----|------|--------|
| `Space` `j` | Normal / Visual | Move line(s) down |
| `Space` `k` | Normal / Visual | Move line(s) up |

#### Navigation

| Key | Action |
|-----|--------|
| `Space` `gg` | Go to top of file |
| `Space` `G` | Go to bottom of file |
| `Space` `a` | Select all (visual) |

#### Telescope (Fuzzy Finding)

| Key | Action |
|-----|--------|
| `Space` `ff` | Find files |
| `Space` `fg` | Live grep |
| `Space` `fb` | Find open buffers |
| `Space` `fh` | Help tags |
| `Space` `fs` | Git status |
| `Space` `fc` | Git commits |
| `Space` `fr` | LSP references |
| `Space` `fd` | LSP definitions |

#### Multi-Cursor (vim-visual-multi)

| Key | Action |
|-----|--------|
| `Space` `d` | Start multi-cursor on word under cursor (repeat to add more) |
| `Space` `D` | Select all occurrences of word |
| `Space` `x` | Skip current occurrence |
| `Space` `X` | Remove current cursor |

Note: `Add Cursor Down/Up` (formerly `Ctrl+Shift+Down/Up`) has been removed. Use repeated `Space` `d` to add cursors to additional occurrences.

### Tier 3 — Standard Vim Motions (not overridden)

These are native Vim bindings. They are intentionally NOT overridden in Potions — use them as-is.

| Key | Action |
|-----|--------|
| `0` | Beginning of line |
| `^` | First non-blank character |
| `$` | End of line |
| `gg` | Top of file |
| `G` | Bottom of file |
| `{` | Previous paragraph |
| `}` | Next paragraph |
| `w` | Forward word |
| `b` | Backward word |
| `e` | End of word |
| `Ctrl+u` | Scroll half-page up |
| `Ctrl+d` | Scroll half-page down |

---

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
- All `Leader+` combinations in Neovim

### Terminal-Specific Escape Sequences

Different terminals send different escape sequences for the same key combination:

#### Word Navigation (`Ctrl+Arrow`)

| Terminal | Right Arrow | Left Arrow |
|----------|-------------|------------|
| iTerm2 | `^[[1;5C` | `^[[1;5D` |
| Terminal.app | `^[f` (Alt+f) | `^[b` (Alt+b) |
| Alacritty | `^[[1;5C` | `^[[1;5D` |
| Zellij | `^[[5C` | `^[[5D` |
| VS Code Terminal | `^[[1;5C` | `^[[1;5D` |

The `.zshrc` configuration includes bindings for all common terminals.

---

## Known Conflicts and Resolutions

### Resolved Conflicts

| Conflict | Old Binding | Resolution |
|----------|-------------|------------|
| `Ctrl+a` — Zellij prefix vs line start | Neovim had `Ctrl+a` = beginning of line | **Removed from Neovim**; use `0` or `^` |
| `Ctrl+e` — end of line | Neovim had `Ctrl+e` = end of line | **Removed from Neovim**; use `$` |
| `Ctrl+u/d` — fixed-line scroll | Neovim overrode with 10-line jump | **Removed**; Vim defaults (half-page) restored |
| `Ctrl+{/}` — paragraph nav | Neovim had redundant remaps | **Removed**; Vim native `{` `}` work natively |
| `Ctrl+k/j` — move lines | Conflicted with Zellij pane resize | **Removed**; use `Space+j/k` |
| `Ctrl+Shift+h/l` — buffer nav | Unreliable across terminals | **Removed**; use `Space+h/l` or `Tab/S-Tab` |
| `Ctrl+Shift+H/L` — move buffer | Unreliable across terminals | **Removed**; use `Space+H/L` |
| `Ctrl+Shift+Up/Down` — move lines | Unreliable across terminals | **Removed**; use `Space+j/k` |
| `Ctrl+Shift+l` — multi-cursor select all | Conflicted with buffer nav | **Changed** to `Space+D` |
| `Ctrl+Shift+k` — multi-cursor remove | Unreliable across terminals | **Changed** to `Space+X` |
| `Ctrl+x` — buffer delete vs cut | Both Neovim | **Buffer delete** moved to `Space+bx` |
| `Ctrl+d` — multi-cursor vs scroll | Both Neovim | **Multi-cursor** changed to `Space+d` |

### Potential Conflicts (User Awareness)

| Keys | Conflict | Mitigation |
|------|----------|------------|
| `Ctrl+d` | Shell EOF vs Vim half-page | Be careful at command line; inside Neovim it half-page scrolls |

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

**Zellij**: Add to `~/.potions/zellij/user.kdl` (preserved on upgrade)

**Zsh**: Add to `~/.potions/config/aliases.zsh` (preserved on upgrade)

### Overriding Default Bindings

To override a default binding, add your custom binding in the user files above. User configurations are loaded after default configurations.

---

## Troubleshooting

### Key Not Working

1. **Check terminal support**: Some terminals don't send certain key sequences
2. **Check for conflicts**: Use `cat -v` or `showkey -a` to see what your terminal sends
3. **Check zellij passthrough**: Ensure zellij isn't intercepting the key

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

### Debugging in Zellij

```bash
# Zellij uses KDL configuration - check your config
cat ~/.potions/zellij/config.kdl

# List active keybindings by checking the config file
# Zellij does not have a runtime key listing command like tmux
```
