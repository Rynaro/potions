# Word navigation

Potions includes this plugin by default. It provides the existing Zsh word movement bindings for Ctrl+Left/Right, multiplexer arrow sequences, and terminal-specific Alt+F/B. It runs offline and needs Zsh.

Manage it through Potions Desk or the CLI, then open a new shell.

```sh
potions plugin deactivate word-navigation
potions plugin activate word-navigation
potions plugin uninstall word-navigation
```

Restore the bundled copy offline with `potions plugin install bundled:word-navigation`. An explicitly disabled or removed plugin keeps that choice across Potions upgrades. The bundle is updated with Potions releases. For a customized copy, copy this directory elsewhere, edit `config/init.zsh`, and install its local path with `--force`.

This directory is also a standalone Potions plugin. Install a working copy with `potions plugin install ./word-navigation`. Its shell configuration runs with your account permissions. It defines key bindings without lifecycle hooks, network calls, or file writes.

Install the standalone release through the Shelf with `potions plugin install word-navigation`, or directly with `potions plugin install Rynaro/potions-word-navigation@v1.0.0`. If the bundled plugin is already installed, add `--force` to switch sources deliberately. Replacement preserves its disabled state.

For local development, clone the repository, edit `config/init.zsh`, and install the working copy. Open a new Zsh session to try the bindings.

```sh
git clone https://github.com/Rynaro/potions-word-navigation.git
cd potions-word-navigation
potions plugin validate ./
potions plugin install ./ --force
```
