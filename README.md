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

1. **Clone the Repository:**

    ```sh
    git clone https://github.com/Rynaro/potions.git
    cd potions
    ```

2. **Ensure Scripts are Executable:**

_All package files are already 0755. But in case you want to make sure._


    ```sh
    chmod +x install.sh
    chmod +x packages/common/*.sh
    chmod +x packages/macos/*.sh
    chmod +x packages/wsl/*.sh
    chmod +x packages/termux/*.sh
    ```

3. **Run the Installation Script:**

    ```sh
    ./install.sh
    ```

The script will detect your environment (macOS, WSL, or Termux) and proceed with the appropriate installations and configurations.

## Contributing to the Documentation

Please help us improve Potions' documentation here in this repository!

## License

Potions is released under the MIT License.
