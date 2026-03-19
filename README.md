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

## 🛠️ What's Installed

- **Zsh**: Modern shell with autosuggestions and syntax highlighting
- **Git**: Pre-configured with useful aliases
- **NeoVim**: Powerful editor with modern plugins
- **Zellij**: Terminal multiplexer with intuitive keybindings
- **Development Tools**: curl, wget, OpenVPN, and more

## 💻 CLI Commands

Potions includes a professional CLI for managing your installation:

```bash
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

| Key | Action |
|-----|--------|
| `Ctrl+a c` | New tab |
| `Ctrl+a x` | Close pane |
| `Ctrl+a \|` | Split right |
| `Ctrl+a -` | Split down |
| `Ctrl+a h/j/k/l` | Navigate panes |
| `Ctrl+a n` | Next tab |
| `Ctrl+a p` | Previous tab |
| `Ctrl+Tab` | Next tab (if terminal supports) |

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
| Ctrl+Tab not working | Configure terminal or use `Ctrl+a n` / `Ctrl+a p` in zellij |
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
