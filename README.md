<p align="center"><img src="https://github.com/user-attachments/assets/8d81012c-41d8-4db9-b801-db40ef52be0b" height="200" /></p>

# 🧪 Potions

**One command. Powerful dev environment. Any platform.**

Potions transforms your fresh macOS, WSL, Termux, or Fedora installation into a fully-configured development environment in minutes.

## ✨ Features

- **Cross-Platform**: macOS, WSL (Windows), Termux (Android), Debian/Linux, Fedora
- **Pre-configured Tools**: Zsh, Git, NeoVim, Zellij, and more
- **One-Switch Theming**: WCAG-AAA Alchemist's Orchid palette across shell, NeoVim, Zellij, and your terminal — switch or cycle with `potions theme`
- **First-class Terminals**: Ghostty (Linux/macOS) and Termux (Android) wired automatically, with live theme changes
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

Press `/` to search Zellij, Zsh, and Neovim shortcuts by tool, key, or action. For example, search for `split` to find the pane controls. Press **F1** in Zellij or run `potions keys` to open the browser directly or `potions keys --plain` to print the reference.

### Pinned projects

Pin a project folder once, then open **Projects** from another directory. In Zellij, press **Ctrl+a**, release it, then press **Shift+p** to open Projects over the active pane.

```sh
cd "$HOME/work/Field Notes"
potions projects pin
cd "$HOME"
potions projects
```

Select **Field Notes** and press **Enter**. The Desk now opens its editor, Git view, and new Zellij tabs in that folder. Closing the Desk returns you to the shell directory where you launched it.

In **Projects**, press `p` to pin the Desk’s current folder and `u` to remove the selected bookmark, even if its folder has moved or been deleted. From the shell, use `potions projects list` to print pinned paths or `potions projects unpin "$HOME/work/Field Notes"` to remove one.

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

potions theme cycle      # Cycle the colorscheme (dark | white | sepia)
potions theme set alchemists-orchid white
potions terminal setup   # Wire detected terminals (Ghostty/Termux)
potions terminal status  # Show detected emulators and wiring

potions reload           # Re-apply config everywhere (regenerate + live-push)
potions reload terminal  # Re-apply terminal surfaces only (= potions terminal reload)
```

### Theming & Terminals

Potions ships the **Alchemist's Orchid** palette (WCAG-AAA, astigmatism-friendly)
as one source of truth across the shell, NeoVim, Zellij, and your terminal
emulator. **Ghostty** (Linux/macOS) and **Termux** (Android) are configured
automatically — palette, cursor/selection, and quality-of-life settings — with
live theme switching. See the
[Terminal Setup Guide](.potions/terminal-setup/TERMINAL_SETUP.md).

**`potions reload`** re-applies your current config across every surface in one
command: it regenerates all artifacts, then live-pushes wherever it safely can
(the current terminal's palette via OSC, Termux via `termux-reload-settings`,
Kitty when remote control is on). Surfaces that can't be hot-reloaded from
outside (Zellij, NeoVim, Ghostty) are reported with the exact one-line action to
finish. Scope it with `potions reload [all|terminal|shell|nvim|zellij]`;
`potions terminal reload` is shorthand for the terminal surfaces. Nothing ever
hangs and nothing is over-promised — the printed status matrix is the truth.

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
| `F1` | Open cheatsheet | Works everywhere, no setup |
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

## 🔌 Use and build plugins

Open **Plugins** in Potions Desk or run `potions plugin`. You can install a plugin
from anyone’s GitHub repository, including your own fork. The optional
[Potions Shelf](https://github.com/Rynaro/potions-shelf) lets people discover
community plugins by name. Use `potions plugin search shell` to look for one.

To install a release directly, replace `OWNER/REPO` and the tag with the
publisher’s details. For a community repository, Potions shows the resolved
commit and asks for your approval. Review that revision before accepting. Its hooks and shell configuration run
with your account permissions.

```sh
potions plugin install OWNER/REPO@v1.2.3
```

Shelf maintainers use automated checks and source review to reduce the risk of
malicious code reaching listed plugins. This is a best-effort process and cannot
guarantee that a plugin is free of vulnerabilities or harmful behavior. From
Potions 2.18.1, installs by Shelf name require a current listing and verify the
fetched Git commit against its recorded review revision before running hooks.
Updates retain that registry source and repeat the check. A moved tag stops the
installation until the Shelf reviews and records its new revision.

Direct GitHub installations are outside Shelf screening. Their publishers are
responsible for the code, updates, and support. Potions provides the installation
mechanism, and you choose whether to run that code with your account permissions.

Please report every suspicious Shelf package, even if you are unsure. Include
the package name, repository, commit, and a brief description of the behavior.
Use a public issue for nonsensitive information and follow the security policy
for sensitive reports. Keep credentials and private files out of public reports.
[Report a suspicious package privately](https://github.com/Rynaro/potions-shelf/security/advisories/new)
· [Shelf security policy](https://github.com/Rynaro/potions-shelf/security/policy)

Potions 2.18.0 recorded all remote installs as direct GitHub sources. To move an
existing install onto the reviewed Shelf path, upgrade Potions and explicitly
run `potions plugin install NAME --force` using its catalog name. That replacement
preserves a disabled plugin's state. Direct GitHub installs keep their selected
source and remain outside Shelf triage.

### Bundled word navigation

Potions 2.19.0 provides its existing Ctrl+Arrow and terminal-specific Alt+F/B
word movement through the `word-navigation` plugin. Fresh installs and upgrades
enable the bundled copy automatically, including offline installs. Its bindings
take effect at the same point in Zsh startup as previous releases.

Manage it in Potions Desk or use the CLI, then open a new shell.

```sh
potions plugin deactivate word-navigation
potions plugin activate word-navigation
potions plugin uninstall word-navigation
```

Upgrades preserve a disabled or removed plugin. Restore it offline with
`potions plugin install bundled:word-navigation`. Potions updates the bundled
code with its own releases. An existing user plugin with that name takes
precedence during migration. To develop a separate copy, copy
`plugins/bundled/word-navigation` from the Potions source and install the copied
directory as a local plugin. [Plugin source and usage](plugins/bundled/word-navigation/README.md)

The standalone package is available from its public repository and the Shelf.
Use `--force` when you deliberately switch an existing installation to that
source. Potions preserves the plugin's disabled state during replacement.

```sh
potions plugin install word-navigation --force
```

[Standalone plugin](https://github.com/Rynaro/potions-word-navigation)

### Make your first plugin

A shell plugin needs a manifest and a shell configuration file. Try adding a
command to the scaffold and installing it from your working directory.

```sh
potions plugin create hello
printf '%s\n' 'alias potions-hello="echo Hello from Potions"' >> ./hello/config/init.zsh
potions plugin validate ./hello
potions plugin install ./hello
```

Open a new shell and run `potions-hello`. The local install links to your
project, so later edits take effect in new shells. You can disable or remove
the plugin through the menu. [Plugin authoring guide](plugins/CREATING_PLUGINS.md)

### Share it with others

Publish the contents of `hello/` at the root of a GitHub repository and share
its name or release tag. Direct installs work as soon as the repository is
available. To have it appear in Shelf search, anyone can fork the Shelf,
generate an entry from the plugin, and open a pull request. Contributors can
comment on that PR, and maintainers review the entry and its automated checks
before merging. Users decide what to install.
[Shelf submission guide](https://github.com/Rynaro/potions-shelf/blob/main/CONTRIBUTING.md)
· [Plugin commands and configuration](plugins/README.md)

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

For an upgrade from 2.15.5 or earlier, use the newer `upgrade.sh` from the release you're installing. Earlier cached upgraders can replace customized files with their templates.

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
| Ctrl+S freezes terminal | Potions disables this automatically (`stty -ixon` in `.zshrc`); if it persists in a non-Potions shell, run `stty -ixon` |

## 🗑️ Uninstalling

To remove Potions while preserving your customizations:

```bash
curl -fsSL https://raw.githubusercontent.com/Rynaro/potions/main/uninstall.sh | bash
```

## 🤝 Contributing

You can report a problem, suggest a change, test on your platform, or review an
open pull request. When reporting a plugin issue, include the Potions version,
the plugin repository and revision, and the command you ran.
[Potions issues](https://github.com/Rynaro/potions/issues)
· [Open pull requests](https://github.com/Rynaro/potions/pulls)

## 📜 License

MIT License
