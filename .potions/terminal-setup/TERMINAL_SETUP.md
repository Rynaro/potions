# Terminal Configuration Guide

This guide helps you configure your terminal emulator for optimal compatibility with Potions keybindings.

---

## macOS: Cmd vs Ctrl Key Interception

macOS terminal emulators intercept `Cmd+<key>` at the application (Cocoa) layer before input reaches the PTY. Zellij — running inside the PTY — never sees `Cmd` shortcuts.

**Impact on Zellij bindings:**

| macOS Shortcut | Terminal Action | Zellij Binding | Always-Working Alternative |
|---|---|---|---|
| `Cmd+A` | Select All | `Ctrl+a` (prefix key) | Press **Ctrl**, not ⌘ |
| `Cmd+D` | (varies by terminal) | `Alt+d` (split right) | `Alt+d` or `Ctrl+a \|` |
| `Cmd+T` | New terminal tab | `Alt+t` (new tab) | `Alt+t` or `Ctrl+a c` |
| `Cmd+W` | Close window/tab | `Alt+w` (close pane) | `Alt+w` or `Ctrl+a x` |
| `Cmd+Return` | Fullscreen (terminal) | `Alt+Enter` (fullscreen) | `Alt+Enter` or `Ctrl+a z` |
| `Cmd+Shift+]` | Next tab (terminal) | `Alt+n` (next tab) | `Alt+n` or `Ctrl+a n` |
| `Cmd+Shift+[` | Prev tab (terminal) | `Alt+p` (prev tab) | `Alt+p` or `Ctrl+a p` |

**Diagnosis — if a Zellij binding does nothing:**

```bash
cat -v
# Press your key combination and observe:
# Ctrl+a  →  prints ^A          ✓ Zellij will receive it
# Cmd+A   →  nothing / selects text   ✗ terminal intercepted it
```

**Troubleshooting: tmux mode (`Ctrl+a`) never activates**

Most common cause on macOS: pressing `Cmd+A` (⌘A) instead of `Ctrl+a`. The **Ctrl** key is in the bottom-left corner of a Mac keyboard; **⌘ Cmd** is next to the spacebar.

### Restoring Cmd Muscle Memory (Optional)

Configure your terminal to forward `Cmd+<key>` as `Alt+<key>` (escape sequence `\e<key>`) — the PTY receives it as `Alt`, and Zellij's `Alt+<key>` bindings fire. See per-terminal instructions below.

---

## iTerm2 (macOS) - Recommended

iTerm2 has the best key binding support on macOS.

### Installation

```bash
brew install --cask iterm2
```

### Option Key as Meta (Required for Alt+key bindings)

1. Go to Preferences → Profiles → Keys
2. Set "Left Option Key" to **Esc+**
3. Set "Right Option Key" to "Esc+" (optional)

This enables `Alt+h/j/k/l`, `Alt+d`, `Alt+t`, `Alt+w`, `Alt+n`, `Alt+p`, and `Alt+Enter`.

### Key Mapping Configuration

1. Open iTerm2 → Preferences → Profiles → Keys → Key Mappings
2. Click "+" to add new mappings:

| Key Combination | Action | Send | Purpose |
|-----------------|--------|------|---------|
| `Ctrl+Tab` | Send Escape Sequence | `[27;5;9~` | Next tab (Zellij) |
| `Ctrl+Shift+Tab` | Send Escape Sequence | `[27;6;9~` | Prev tab (Zellij) |

### Cmd→Alt Forwarding (Restores macOS Muscle Memory)

After setting Option Key to "Esc+", add these mappings so `Cmd+<key>` fires Zellij's `Alt+<key>` bindings:

1. Preferences → Profiles → Keys → Key Mappings → "+"
2. Set **Keyboard Shortcut**, choose **Send Escape Sequence** as action, enter the value:

| Keyboard Shortcut | Action | Escape Sequence Value | Zellij Action |
|---|---|---|---|
| `Cmd+D` | Send Escape Sequence | `d` | Split pane right |
| `Cmd+T` | Send Escape Sequence | `t` | New tab |
| `Cmd+W` | Send Escape Sequence | `w` | Close pane |
| `Cmd+N` (next) | Send Escape Sequence | `n` | Next tab |
| `Cmd+P` (prev) | Send Escape Sequence | `p` | Previous tab |

> Note: `Cmd+Return` cannot be mapped this way in iTerm2. Use `Alt+Enter` directly or `Ctrl+a z`.

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

### Enable Option as Meta (Required for Alt+key bindings)

1. Terminal → Preferences → Profiles → Keyboard
2. Check **"Use Option as Meta key"**

This enables `Alt+h/j/k/l`, `Alt+d`, `Alt+t`, `Alt+w`, `Alt+n`, `Alt+p`, and `Alt+Enter`.
With Option as Meta, press **Option+<key>** wherever you would press `Cmd+<key>` on other terminals.

### Workarounds

Use these alternative bindings in Terminal.app:

| Default Binding | Terminal.app Alternative |
|-----------------|-------------------------|
| `Ctrl+Tab` (next tab) | `Alt+n` or `Ctrl+a n` |
| `Ctrl+Shift+Tab` (prev tab) | `Alt+p` or `Ctrl+a p` |
| `Cmd+D` (split right) | `Option+d` (after enabling Option as Meta) |
| `Cmd+T` (new tab) | `Option+t` |
| `Cmd+W` (close pane) | `Option+w` |
| `Ctrl+Right` (forward word) | `Alt+f` (Option+f) |
| `Ctrl+Left` (backward word) | `Alt+b` (Option+b) |

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

### Cmd→Alt Forwarding (macOS, restores Cmd muscle memory)

```
map cmd+d send_key alt+d
map cmd+t send_key alt+t
map cmd+w send_key alt+w
map cmd+n send_key alt+n
map cmd+p send_key alt+p
map cmd+enter send_key alt+enter
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
    -- macOS: forward Cmd+<key> → Alt+<key> for Zellij bindings
    { key = "d", mods = "CMD", action = wezterm.action.SendString("\x1bd") },
    { key = "t", mods = "CMD", action = wezterm.action.SendString("\x1bt") },
    { key = "w", mods = "CMD", action = wezterm.action.SendString("\x1bw") },
    { key = "n", mods = "CMD", action = wezterm.action.SendString("\x1bn") },
    { key = "p", mods = "CMD", action = wezterm.action.SendString("\x1bp") },
    { key = "Return", mods = "CMD", action = wezterm.action.SendString("\x1b\r") },
  },
}
```

---

## VS Code / Cursor Integrated Terminal

The integrated terminal in VS Code and Cursor works well with most bindings.

### Note on Zellij

By default, Potions does not auto-start zellij in VS Code/Cursor terminals to avoid terminal capture issues. You can manually start zellij if needed:

```bash
zellij
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

#### Ctrl+Tab not working in zellij

Your terminal may not send the correct escape sequence. Use the alternative:
- Press `Ctrl+a` then `n` for next tab
- Press `Ctrl+a` then `p` for previous tab

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
