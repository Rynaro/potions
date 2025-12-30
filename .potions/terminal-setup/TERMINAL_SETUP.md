# Terminal Configuration Guide

This guide helps you configure your terminal emulator for optimal compatibility with Potions keybindings.

---

## iTerm2 (macOS) - Recommended

iTerm2 has the best key binding support on macOS.

### Installation

```bash
brew install --cask iterm2
```

### Key Mapping Configuration

1. Open iTerm2 → Preferences → Profiles → Keys → Key Mappings
2. Click "+" to add new mappings:

| Key Combination | Action | Send |
|-----------------|--------|------|
| Ctrl+Tab | Send Escape Sequence | `[27;5;9~` |
| Ctrl+Shift+Tab | Send Escape Sequence | `[27;6;9~` |

### Option Key as Meta

For Alt+key combinations:

1. Go to Preferences → Profiles → Keys
2. Set "Left Option Key" to "Esc+"
3. Set "Right Option Key" to "Esc+" (optional)

### Import Profile (Optional)

You can import the provided `iterm2-profile.json`:

1. Preferences → Profiles → Other Actions → Import JSON Profiles
2. Select `~/.potions/terminal-setup/iterm2-profile.json`

---

## Terminal.app (macOS)

Terminal.app has limited key binding support but still works with Potions.

### Limitations

- Ctrl+Tab does not work natively
- Some Ctrl+Shift combinations may not work

### Workarounds

Use these alternative bindings in Terminal.app:

| Default Binding | Terminal.app Alternative |
|-----------------|-------------------------|
| Ctrl+Tab (tmux next window) | Prefix + n (`Ctrl+a n`) |
| Ctrl+Shift+Tab (tmux prev window) | Prefix + p (`Ctrl+a p`) |
| Ctrl+Right (forward word) | Alt+f (Option+f) |
| Ctrl+Left (backward word) | Alt+b (Option+b) |

### Enable Option as Meta

1. Terminal → Preferences → Profiles → Keyboard
2. Check "Use Option as Meta key"

---

## Alacritty

Alacritty is a fast, GPU-accelerated terminal emulator.

### Installation

```bash
brew install --cask alacritty
```

### Configuration

Create or edit `~/.config/alacritty/alacritty.toml`:

```toml
[keyboard]
bindings = [
  { key = "Tab", mods = "Control", chars = "\u001b[27;5;9~" },
  { key = "Tab", mods = "Control|Shift", chars = "\u001b[27;6;9~" },
  { key = "Right", mods = "Control", chars = "\u001b[1;5C" },
  { key = "Left", mods = "Control", chars = "\u001b[1;5D" },
]
```

Or for older YAML format (`~/.config/alacritty/alacritty.yml`):

```yaml
key_bindings:
  - { key: Tab, mods: Control, chars: "\x1b[27;5;9~" }
  - { key: Tab, mods: Control|Shift, chars: "\x1b[27;6;9~" }
  - { key: Right, mods: Control, chars: "\x1b[1;5C" }
  - { key: Left, mods: Control, chars: "\x1b[1;5D" }
```

---

## Kitty

### Installation

```bash
brew install --cask kitty
```

### Configuration

Add to `~/.config/kitty/kitty.conf`:

```
map ctrl+tab send_text all \x1b[27;5;9~
map ctrl+shift+tab send_text all \x1b[27;6;9~
map ctrl+right send_text all \x1b[1;5C
map ctrl+left send_text all \x1b[1;5D
```

---

## WezTerm

### Installation

```bash
brew install --cask wezterm
```

### Configuration

Create `~/.wezterm.lua`:

```lua
local wezterm = require 'wezterm'

return {
  keys = {
    { key = "Tab", mods = "CTRL", action = wezterm.action.SendString("\x1b[27;5;9~") },
    { key = "Tab", mods = "CTRL|SHIFT", action = wezterm.action.SendString("\x1b[27;6;9~") },
    { key = "RightArrow", mods = "CTRL", action = wezterm.action.SendString("\x1b[1;5C") },
    { key = "LeftArrow", mods = "CTRL", action = wezterm.action.SendString("\x1b[1;5D") },
  },
}
```

---

## VS Code / Cursor Integrated Terminal

The integrated terminal in VS Code and Cursor works well with most bindings.

### Note on Tmux

By default, Potions does not auto-start tmux in VS Code/Cursor terminals to avoid terminal capture issues. You can manually start tmux if needed:

```bash
tmux
```

### Key Binding Conflicts

Some key bindings may be intercepted by the editor. To release them:

1. Open Command Palette (Cmd+Shift+P)
2. Search "Preferences: Open Keyboard Shortcuts (JSON)"
3. Add entries to release keys to terminal:

```json
{
  "key": "ctrl+shift+h",
  "command": "-workbench.action.focusPreviousGroup"
},
{
  "key": "ctrl+shift+l",
  "command": "-workbench.action.focusNextGroup"
}
```

---

## Troubleshooting

### Test What Your Terminal Sends

To see what escape sequence your terminal sends for a key:

```bash
cat -v
# Then press the key combination
# Press Ctrl+C to exit
```

### Common Issues

#### Ctrl+Tab not working in tmux

Your terminal may not send the correct escape sequence. Use the alternative:
- Press `Ctrl+a` then `n` for next window
- Press `Ctrl+a` then `p` for previous window

#### Word navigation not working

Try these alternatives:
- Alt+f / Alt+b (Option+f / Option+b on Mac)
- Configure your terminal to send proper escape sequences (see above)

#### Ctrl+S freezes terminal

This is the terminal's XON/XOFF flow control. Potions should disable it automatically, but if not:

```bash
# Add to your shell config
stty -ixon
```

To unfreeze: Press `Ctrl+Q`

---

## Quick Reference

### Escape Sequences Reference

| Key | Escape Sequence |
|-----|-----------------|
| Ctrl+Right | `\x1b[1;5C` or `^[[1;5C` |
| Ctrl+Left | `\x1b[1;5D` or `^[[1;5D` |
| Ctrl+Tab | `\x1b[27;5;9~` |
| Ctrl+Shift+Tab | `\x1b[27;6;9~` |
| Alt+f | `\x1bf` or `^[f` |
| Alt+b | `\x1bb` or `^[b` |

### Terminal Compatibility Matrix

| Terminal | Ctrl+Tab | Ctrl+Arrow | Alt+Key | Rating |
|----------|----------|------------|---------|--------|
| iTerm2 | ✅ (config) | ✅ | ✅ | ⭐⭐⭐⭐⭐ |
| Alacritty | ✅ (config) | ✅ | ✅ | ⭐⭐⭐⭐⭐ |
| Kitty | ✅ (config) | ✅ | ✅ | ⭐⭐⭐⭐⭐ |
| WezTerm | ✅ (config) | ✅ | ✅ | ⭐⭐⭐⭐⭐ |
| Terminal.app | ❌ | ⚠️ | ✅ (config) | ⭐⭐⭐ |
| VS Code | ⚠️ | ✅ | ⚠️ | ⭐⭐⭐⭐ |
