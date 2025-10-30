<p align="center"><img src="https://github.com/user-attachments/assets/8d81012c-41d8-4db9-b801-db40ef52be0b" height="200" /></p>

# 🧪 Potions

**One command. Powerful dev environment. Any platform.**

Potions transforms your fresh macOS, WSL, or Termux installation into a fully-configured development environment in minutes. Stop wasting time with tedious configuration - start coding faster!

## ✨ Features

- **Cross-Platform**: Works on macOS, WSL (Windows), and Termux (Android)
- **Pre-configured Tools**: Zsh, Git, NeoVim, Tmux, and more
- **Modern Terminal**: Beautiful prompt with Git integration
- **Plugin System**: Extend functionality with custom plugins
- **Fast Setup**: Just one command to get started

## 🚀 Quick Start

### One-Line Installation (Recommended)

The one-line installer will help you install essential packages (git, curl, unzip) from your operating system's official repositories if they're not already present on your system.

Using curl:
```bash
curl -fsSL https://raw.githubusercontent.com/Rynaro/potions/main/drink.sh | bash
```

Using wget:
```bash
wget -O- https://raw.githubusercontent.com/Rynaro/potions/main/drink.sh | bash
```

### Manual Installation

```bash
# Clone the repo
git clone https://github.com/Rynaro/potions.git

# Enter directory
cd potions

# Make scripts executable (Optional)
chmod +x install.sh
chmod +x packages/*/*/*.sh

# Run installer
./install.sh
```

After installation, restart your terminal or type `zsh` to begin using your new environment!

## 🔄 Upgrading Potions

Keep your Potions installation up to date with a single command:

### One-Line Upgrade

```bash
curl -fsSL https://raw.githubusercontent.com/Rynaro/potions/main/upgrade.sh | bash
```

### Manual Upgrade

If you installed Potions manually by cloning the repository:

```bash
cd ~/.potions/.repo  # repository is stored here
git pull origin main
cd ~
curl -fsSL https://raw.githubusercontent.com/Rynaro/potions/main/upgrade.sh | bash
```

Or if you're in the repository directory:

```bash
git pull origin main
./upgrade.sh
```

### What the Upgrader Does

The upgrade script safely updates your Potions installation while:
- ✅ **Creating automatic backups** in `~/.potions/backups/` (keeps last 5 backups)
- ✅ **Preserving user customizations** in `.zsh_aliases` and `sources/*.sh` files
- ✅ **Updating configuration files** with the latest improvements
- ✅ **Storing repository** in `~/.potions/.repo` for faster future upgrades
- ✅ **Providing rollback instructions** if something goes wrong

All upgrade-related files are consolidated in `~/.potions` to keep your HOME directory clean:
- `~/.potions/.repo` - Git repository for upgrades
- `~/.potions/backups/` - Backup directories

After upgrading, restart your terminal or run `exec zsh` to apply changes.

**Note**: Custom additions to `.zsh_aliases` are automatically merged. For `sources/*.sh` files, your originals are backed up with a `.backup` extension for manual review.

## 🔌 Plugin System

Potions includes a plugin system to extend functionality:

### Install Plugins
```bash
# Create a plugins.txt file with your desired plugins
echo "Rynaro/mini-rails" > plugins.txt

# Install plugins
./plugins.sh install
```

### Create Your Own Plugin
```bash
# Scaffold a new plugin
./plugins.sh create my_awesome_plugin
```

## 🛠️ What's Included

- **Zsh**: Modern shell with autosuggestions and syntax highlighting
- **Git**: Pre-configured with useful aliases
- **NeoVim**: Powerful editor with modern plugins and macOS-friendly keybindings
- **Tmux**: Terminal multiplexer with VSCode-like keybindings, optimized for macOS
- **Development Tools**: curl, wget, OpenVPN, and more
- **📚 Complete Cheatsheet**: See [CHEATSHEET.md](CHEATSHEET.md) for all keybindings

## 📝 Configuration

All configurations are stored in `~/.potions`:
- `.zshrc`: Main Zsh configuration
- `.zsh_aliases`: Custom command aliases
- `nvim/init.vim`: NeoVim configuration
- `tmux/tmux.conf`: Tmux configuration
- `sources/{linux|wsl|termux|macos}.sh`: Your customized source files per OS

## 📚 Documentation

- **[CHEATSHEET.md](CHEATSHEET.md)**: Complete reference guide for all keybindings and shortcuts
  - Tmux keybindings and shortcuts
  - Neovim commands and navigation
  - macOS-optimized workflows
  - Quick tips and best practices

## 🤝 Contributing

Contributions are welcome! Help improve Potions by:
- Submitting bug reports and feature requests
- Improving documentation
- Adding support for new platforms
- Creating new plugins

## 📜 License

Potions is released under the MIT License.
