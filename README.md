<p align="center"><img src="https://github.com/user-attachments/assets/8d81012c-41d8-4db9-b801-db40ef52be0b" height="200" /></p>

# 🧪 Potions

**One command. Powerful dev environment. Any platform.**

Potions transforms your fresh macOS, WSL, Termux, or Fedora installation into a fully-configured development environment in minutes.

## ✨ Features

- **Cross-Platform**: macOS, WSL (Windows), Termux (Android), Debian/Linux, Fedora
- **Pre-configured Tools**: Zsh, Git, NeoVim, Zellij, and more
- **Professional CLI**: Manage your installation with `potions` commands
- **Plugin System**: Extend functionality with custom plugins
- **User Customization**: Preserved settings that survive upgrades

## 🚀 Quick Start

### One-Line Installation

```bash
curl -fsSL https://raw.githubusercontent.com/Rynaro/potions/main/drink.sh | bash
```

After installation, restart your terminal or type `zsh` to begin using your new environment!

## Potions Desk

Press **Ctrl+a**, release it, then press **Space** in Zellij to open the desk over your current pane. From a shell, run `potions` or `potions desk`. Move with the arrow keys or `j` and `k`, press **Enter** to open an item, and press `q` to return to work.

From the desk you can inspect the Git working tree, run an installation health check, or open the current directory in your editor. In Zellij, **New terminal tab** closes the desk and opens a shell tab in that directory.

The scratchpad lives at `$POTIONS_HOME/notes.md` (normally `~/.potions/notes.md`) and stays available across projects and sessions. The desk uses `VISUAL`, then `EDITOR`, and falls back to `nvim` or `vi`. An editor command can include simple flags such as `code --wait`. Use an executable wrapper for arguments that require shell quoting.

Press `/` to search Zellij, Zsh, and Neovim shortcuts by tool, key, or action. For example, search for `split` to find the pane controls. Run `potions keys` to open the browser directly or `potions keys --plain` to print the reference.

## 🛠️ What's Installed

- **Zsh**: Modern shell with autosuggestions and syntax highlighting
- **Git**: Pre-configured with useful aliases
- **NeoVim**: Powerful editor with modern plugins
- **Zellij**: Terminal multiplexer with intuitive keybindings
- **Development Tools**: curl, wget, OpenVPN, and more

## 💻 CLI Commands

Potions includes a professional CLI for managing your installation:

```bash
potions desk             # Open the terminal desk
potions keys             # Search keyboard shortcuts
potions upgrade          # Upgrade to latest version
potions update           # Check for updates
potions version          # Show current version
potions status           # Show installation status
potions info             # Show system information
potions doctor           # Run health check
potions help             # Show help message
```

## 📝 Configuration

All configurations are stored in `~/.potions`:

### Managed Files (Do Not Edit)

These files are overwritten on upgrade:

- `.zshrc` - Main Zsh configuration
- `nvim/init.vim` - NeoVim configuration
- `zellij/config.kdl` - Zellij configuration

### User Customization (Preserved on Upgrade)

Add your customizations here—they survive upgrades:

| File | Purpose |
|------|---------|
| `config/aliases.zsh` | Custom aliases and functions |
| `config/secure.zsh` | Private configurations (gitignored) |
| `config/local.zsh` | Machine-specific settings |
| `config/{macos\|linux\|wsl\|termux}.zsh` | Platform-specific customizations |
| `nvim/user.vim` | Your Neovim extensions |
| `zellij/user.kdl` | Your Zellij extensions |

### Legacy Files (Still Supported)

- `.zsh_aliases` - Legacy aliases (use `config/aliases.zsh` instead)
- `sources/*.sh` - Legacy platform configs (use `config/*.zsh` instead)

Run `./migrate.sh` to migrate from legacy to new structure.

## ⌨️ Keybindings Quick Reference

### Zellij (Prefix: `Ctrl+a`)

> **macOS users:** The prefix is `Ctrl+a` (hold Control, press A) — **not** `Cmd+A`. `Cmd+A` triggers "Select All" in your terminal and never reaches Zellij. See the [Terminal Setup Guide](.potions/terminal-setup/TERMINAL_SETUP.md) for macOS-specific setup.

| Key | Action | macOS Notes |
|-----|--------|-------------|
| `Ctrl+a Space` | Open Potions desk | Press Space after releasing the prefix |
| `Ctrl+a c` | New tab | or `Alt+t` |
| `Ctrl+a x` | Close pane | or `Alt+w` |
| `Ctrl+a \|` | Split right | or `Alt+d` |
| `Ctrl+a -` | Split down | — |
| `Ctrl+a h/j/k/l` | Navigate panes | or `Alt+h/j/k/l` |
| `Ctrl+a n` | Next tab | or `Alt+n` |
| `Ctrl+a p` | Previous tab | or `Alt+p` |
| `Ctrl+a z` | Toggle fullscreen | or `Alt+Enter` |
| `Ctrl+Tab` | Next tab | Not forwarded by Terminal.app — use `Alt+n` |

### Neovim (Leader: `Space`)

| Key | Action |
|-----|--------|
| `Ctrl+n` | Toggle NERDTree file explorer |
| `Space ff` | Find files (Telescope) |
| `Space fg` | Live grep |
| `Space fb` | Find buffers |
| `Space 1-9` | Go to buffer N |
| `Space q` | Quit |
| `Space w` | Save |
| `Ctrl+s` | Quick save |

📖 **Full reference**: [`.potions/KEYMAPS.md`](.potions/KEYMAPS.md)

## 🔌 Plugin System

```bash
# Install plugins
echo "Rynaro/mini-rails" > plugins.txt
./plugins.sh install

# Create your own plugin
./plugins.sh create my_awesome_plugin
```

## 🧪 Test Mode

Test the installation interface without modifying your system:

```bash
./install.sh --test
./drink.sh --test
```

## 🔄 Upgrading

### Using CLI (Recommended)

```bash
potions upgrade
```

### Manual Upgrade

For an upgrade from 2.12.1 or earlier, use the newer `upgrade.sh` from the release you're installing. Earlier cached upgraders can replace customized files with their templates.

```bash
curl -fsSL https://raw.githubusercontent.com/Rynaro/potions/main/upgrade.sh | bash
```

The upgrade script:
- ✅ Creates automatic backups in `~/.potions/backups/` (keeps last 5)
- ✅ Preserves user customizations in `config/*.zsh` and user files
- ✅ Updates configuration files with latest improvements

After upgrading, restart your terminal or run `exec zsh` to apply changes.

## 🔧 Troubleshooting

### Terminal Key Bindings Not Working

Some terminals require configuration for certain key combinations. See the [Terminal Setup Guide](.potions/terminal-setup/TERMINAL_SETUP.md) for:
- iTerm2 configuration
- Alacritty settings
- Terminal.app workarounds

### Common Issues

| Issue | Solution |
|-------|----------|
| Tmux mode (`Ctrl+a`) does not activate on macOS | You may be pressing `Cmd+A` (⌘A) instead of `Ctrl+a`. Use `cat -v` to verify. |
| `Ctrl+Tab` not working | Use `Alt+n` or `Ctrl+a n`; or configure terminal (see Terminal Setup Guide) |
| `Cmd+D/T/W` does nothing in Zellij | These are intercepted by macOS. Use `Alt+d/t/w` or configure Cmd→Alt forwarding |
| Word navigation broken | Check terminal key mappings, try Alt+f/Alt+b |
| Ctrl+S freezes terminal | Potions should disable this; if not, run `stty -ixon` |

## 🗑️ Uninstalling

To remove Potions while preserving your customizations:

```bash
curl -fsSL https://raw.githubusercontent.com/Rynaro/potions/main/uninstall.sh | bash
```

## 🤝 Contributing

Contributions welcome! Help improve Potions by submitting bug reports, improving documentation, adding platform support, or creating plugins.

## 📜 License

MIT License
