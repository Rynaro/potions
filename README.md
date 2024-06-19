# Potions

Turn a fresh installation of macOS, WSL, or Termux into a fully-configured, beautiful, and modern development environment by running a single command. That's the one-line pitch for Potions. No need to write bespoke configs for every essential tool just to get started or to be up on all the latest command-line tools. Potions is an opinionated take on what your development setup can be at its best.

## Features

- Installs and configures essential tools:
  - Git
  - Zsh
  - curl
  - OpenVPN
  - rbenv
  - nvm
  - Neovim
- Environment-specific installations for macOS, WSL, and Termux.
- Configures Zsh as the default shell.
- Sets up custom Zsh configurations and aliases.

## Installation

1. Clone the Repository:
    ```sh
    git clone https://github.com/Rynaro/potions.git
    cd potions
    ```

2. Ensure Scripts are Executable:
    ```sh
    chmod +x install.sh
    chmod +x packages/common/*.sh
    chmod +x packages/macos/*.sh
    chmod +x packages/wsl/*.sh
    chmod +x packages/termux/*.sh
    ```

3. Run the Installation Script:
    ```sh
    ./install.sh
    ```
    The script will detect your environment (macOS, WSL, or Termux) and proceed with the appropriate installations and configurations.

## Plugin Management System

### Introduction

The plugin management system allows users to create, install, and manage plugins efficiently. The system is structured to enable easy scaffolding and integration of plugins into the Potions ecosystem.

### Plugin Installation

1. Run the plugin management script:
    ```sh
    ./plugins.sh install
    ```

### Creating a Plugin

To create a new plugin, run:
```sh
./plugins.sh create <plugin_name>
```
This command scaffolds a new plugin structure under the `plugins` directory.

### Plugin Structure

A plugin consists of the following components:

- `install.sh`: Script to handle the installation process.
- `packages`: Directory for package-specific scripts.
- `utilities.sh`: Utility functions for common tasks.

### Managing Plugins

- **Install Plugins**:
    ```sh
    ./plugins.sh install
    ```
    This command reads `plugins.txt` and installs the listed plugins.

- **Obtain Plugins**:
    The `obtain.sh` script clones repositories specified in `plugins.txt`.

### Utilities

The `utilities.sh` script includes functions to check the environment, update repositories, and safely source other scripts.

### Example

To scaffold a plugin named `example_plugin`:
```sh
./plugins.sh create example_plugin
```

### Example `plugins.txt`

Create a `plugins.txt` file in the root directory with the following content to include the `Rynaro/mini-rails` plugin:
```txt
Rynaro/mini-rails
```

## Contributing to the Documentation

Please help us improve Potions' documentation here in this repository!

## License

Potions is released under the MIT License.
