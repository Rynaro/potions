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

## 🔌 Plugin System

Potions includes a plugin system to extend functionality. After running the
installer, plugin management tools are placed inside `~/.potions`:

### Install Plugins
```bash
# Create a plugins.txt file with your desired plugins
echo "Rynaro/mini-rails" > ~/.potions/plugins.txt

# Install plugins
~/.potions/plugins.sh install
```

### Create Your Own Plugin
```bash
# Scaffold a new plugin
~/.potions/plugins.sh create my_awesome_plugin
```

## 🛠️ What's Included

- **Zsh**: Modern shell with autosuggestions and syntax highlighting
- **Git**: Pre-configured with useful aliases
- **NeoVim**: Powerful editor with modern plugins
- **Tmux**: Terminal multiplexer with VSCode-like keybindings
- **Development Tools**: curl, wget, OpenVPN, and more

## 📝 Configuration

All configurations are stored in `~/.potions`:
- `.zshrc`: Main Zsh configuration
- `.zsh_aliases`: Custom command aliases
- `nvim/init.vim`: NeoVim configuration
- `tmux/tmux.conf`: Tmux configuration
- `sources/{linux|wsl|termux|macos}.sh`: Your customized source files per OS

## 🤝 Contributing

Contributions are welcome! Help improve Potions by:
- Submitting bug reports and feature requests
- Improving documentation
- Adding support for new platforms
- Creating new plugins

## 📜 License

Potions is released under the MIT License.
