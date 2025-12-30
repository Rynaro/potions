<p align="center"><img src="https://github.com/user-attachments/assets/8d81012c-41d8-4db9-b801-db40ef52be0b" height="200" /></p>

# 🧪 Potions

**One command. Powerful dev environment. Any platform.**

Potions transforms your fresh macOS, WSL, or Termux installation into a fully-configured development environment in minutes.

## ✨ Features

- **Cross-Platform**: macOS, WSL (Windows), Termux (Android), Debian/Linux
- **Pre-configured Tools**: Zsh, Git, NeoVim, Tmux, and more
- **Professional CLI**: Manage your installation with `potions` commands
- **Modern Terminal**: Beautiful prompt with Git integration
- **User Customization**: Preserved settings that survive upgrades
- **Plugin System**: Extend functionality with custom plugins
- **Fast Setup**: One command to get started

## 🚀 Quick Start

### One-Line Installation

```bash
curl -fsSL https://raw.githubusercontent.com/Rynaro/potions/main/drink.sh | bash
```

After installation, restart your terminal or type `zsh` to begin using your new environment!

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

### Examples

```bash
# Check if updates are available
potions update

# Upgrade to latest version
potions upgrade

# Check installation health
potions doctor
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
- ✅ Preserves user customizations in `.zsh_aliases` and `sources/*.sh`
- ✅ Updates configuration files with latest improvements

After upgrading, restart your terminal or run `exec zsh` to apply changes.

## 🛠️ What's Included

- **Zsh**: Modern shell with autosuggestions and syntax highlighting
- **Git**: Pre-configured with useful aliases
- **NeoVim**: Powerful editor with modern plugins
- **Tmux**: Terminal multiplexer with VSCode-like keybindings
- **Development Tools**: curl, wget, OpenVPN, and more

## 📝 Configuration

All configurations are stored in `~/.potions`:

### Managed Files (Do Not Edit)
- `.zshrc`: Main Zsh configuration
- `nvim/init.vim`: NeoVim configuration
- `tmux/tmux.conf`: Tmux configuration

### User Customization (Preserved on Upgrade)
- `config/aliases.zsh`: Your custom aliases and functions
- `config/secure.zsh`: Private/sensitive configurations (gitignored)
- `config/local.zsh`: Machine-specific settings
- `config/{macos|linux|wsl|termux}.zsh`: Platform-specific customizations
- `nvim/user.vim`: Your Neovim extensions
- `tmux/user.conf`: Your Tmux extensions

### Legacy Files (Still Supported)
- `.zsh_aliases`: Legacy aliases (use `config/aliases.zsh` instead)
- `sources/*.sh`: Legacy platform configs (use `config/*.zsh` instead)

Run `./migrate.sh` to migrate from legacy to new structure.

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

## 📚 Documentation

- **[CHEATSHEET.md](CHEATSHEET.md)**: Complete reference for keybindings and shortcuts
- **[KEYMAPS.md](.potions/KEYMAPS.md)**: Unified keymap reference across all tools
- **[Terminal Setup](.potions/terminal-setup/TERMINAL_SETUP.md)**: Configure your terminal for optimal compatibility

## 🔧 Troubleshooting

### Terminal Key Bindings Not Working

Some terminals require configuration for certain key combinations. See the [Terminal Setup Guide](.potions/terminal-setup/TERMINAL_SETUP.md) for:
- iTerm2 configuration
- Alacritty settings
- Terminal.app workarounds

### Common Issues

| Issue | Solution |
|-------|----------|
| Ctrl+Tab not working | Configure terminal or use `Ctrl+a n` / `Ctrl+a p` |
| Word navigation broken | Check terminal key mappings, try Alt+f/Alt+b |
| Ctrl+S freezes terminal | Potions should disable this; if not, run `stty -ixon` |

### Uninstalling

To remove Potions while preserving your customizations:

```bash
curl -fsSL https://raw.githubusercontent.com/Rynaro/potions/main/uninstall.sh | bash
```

## 🤝 Contributing

Contributions welcome! Help improve Potions by submitting bug reports, improving documentation, adding platform support, or creating plugins.

## 📜 License

MIT License
