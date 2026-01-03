# Creating Potions Plugins

A comprehensive guide to creating plugins for the Potions ecosystem.

## Getting Started

### 1. Scaffold Your Plugin

Use the built-in scaffolding tool:

```bash
./plugins.sh create my-awesome-plugin
```

This creates a complete plugin structure with all required files.

### 2. Plugin Structure

```
my-awesome-plugin/
├── plugin.potions.json    # REQUIRED: Plugin manifest
├── install.sh             # REQUIRED: Installation script
├── uninstall.sh           # REQUIRED: Uninstallation script
├── activate.sh            # OPTIONAL: Activation script
├── deactivate.sh          # OPTIONAL: Deactivation script
├── utilities.sh           # Helper functions
├── packages/              # Package installation scripts
│   └── main.sh
├── config/                # Configuration files
│   ├── init.zsh           # Shell configurations
│   └── settings.lua       # NeoVim configurations
└── README.md              # REQUIRED: Documentation
```

## Plugin Manifest

The `plugin.potions.json` file is the heart of your plugin:

```json
{
  "name": "my-awesome-plugin",
  "version": "1.0.0",
  "description": "Does awesome things",
  "author": "Your Name",
  "license": "MIT",
  "potions_min_version": "2.6.0",
  "platforms": ["macos", "linux", "wsl", "termux"],
  "dependencies": [],
  "provides": {
    "nvim": ["colorscheme", "plugin"],
    "shell": ["aliases", "functions"],
    "tmux": ["keybindings"]
  },
  "hooks": {
    "post_install": "",
    "pre_uninstall": ""
  },
  "checksums": {}
}
```

### Required Fields

| Field | Description |
|-------|-------------|
| `name` | Unique plugin name (lowercase, hyphens allowed) |
| `version` | Semantic version (X.Y.Z) |
| `description` | Short description |
| `author` | Plugin author |
| `potions_min_version` | Minimum Potions version required |

### Optional Fields

| Field | Description |
|-------|-------------|
| `license` | License type (default: MIT) |
| `platforms` | Supported platforms |
| `dependencies` | Other plugins required |
| `provides` | Features provided |
| `hooks` | Lifecycle hooks |
| `checksums` | File checksums for verification |

## Writing Scripts

### install.sh

The installation script runs when the plugin is installed:

```bash
#!/bin/bash

PLUGIN_NAME="my-awesome-plugin"
PLUGIN_VERSION="1.0.0"
PLUGIN_RELATIVE_FOLDER="$(dirname "$0")"

source "$PLUGIN_RELATIVE_FOLDER/utilities.sh"

prepare() {
  log "Preparing installation..."
  # Check dependencies, create directories, etc.
}

install_packages() {
  log "Installing plugin..."
  # Install packages, copy files, etc.
}

configure() {
  log "Configuring plugin..."
  # Setup configuration files
}

post_install() {
  log "Plugin installed successfully!"
}

# Run pipeline
prepare
install_packages
configure
post_install
```

### uninstall.sh

The uninstallation script cleans up:

```bash
#!/bin/bash

PLUGIN_NAME="my-awesome-plugin"
PLUGIN_RELATIVE_FOLDER="$(dirname "$0")"

source "$PLUGIN_RELATIVE_FOLDER/utilities.sh"

remove_files() {
  log "Removing plugin files..."
  # Remove installed files
  # Be careful not to remove user customizations!
}

cleanup() {
  log "Cleaning up..."
}

post_uninstall() {
  log "Plugin uninstalled."
}

remove_files
cleanup
post_uninstall
```

### utilities.sh

Common helper functions for your plugin:

```bash
#!/bin/bash

POTIONS_HOME="${POTIONS_HOME:-$HOME/.potions}"
PLUGIN_RELATIVE_FOLDER="${PLUGIN_RELATIVE_FOLDER:-$(dirname "$0")}"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [my-plugin] $*"
}

safe_source() {
  [ -f "$1" ] && source "$1"
}

command_exists() {
  command -v "$1" &> /dev/null
}

is_macos() { [ "$(uname -s)" = "Darwin" ]; }
is_linux() { [ "$(uname -s)" = "Linux" ]; }
is_wsl() { grep -qi microsoft /proc/version 2>/dev/null; }
is_termux() { [ -n "$PREFIX" ] && [ -x "$PREFIX/bin/termux-info" ]; }
```

## Adding Features

### Shell Aliases and Functions

Create `config/init.zsh`:

```bash
# My Awesome Plugin - Shell Configuration

# Aliases
alias my-cmd='echo "Hello from my-awesome-plugin"'

# Functions
my_function() {
  echo "This is a function from my plugin"
}

# Environment variables
export MY_PLUGIN_HOME="$POTIONS_HOME/plugins/my-awesome-plugin"
```

### NeoVim Configuration

Create `config/settings.lua`:

```lua
-- My Awesome Plugin - NeoVim Configuration

local M = {}

M.setup = function()
  -- Add your NeoVim configuration here
  vim.opt.number = true
  
  -- Custom keybindings
  vim.keymap.set('n', '<leader>mp', ':echo "My Plugin"<CR>', {
    desc = 'My plugin command'
  })
end

return M
```

### Package Installation

Create package scripts in `packages/`:

```bash
#!/bin/bash
# packages/main.sh

source "$(dirname "$0")/../utilities.sh"

install_main_package() {
  log "Installing main package..."
  
  if is_macos; then
    brew install some-tool
  elif is_linux; then
    sudo apt-get install -y some-tool
  fi
}

install_main_package
```

## Cross-Platform Support

Always consider all platforms:

```bash
install_dependency() {
  if is_macos; then
    brew install "$1"
  elif is_termux; then
    pkg install -y "$1"
  elif is_wsl || is_linux; then
    sudo apt-get install -y "$1"
  else
    log "Unsupported platform"
    return 1
  fi
}
```

## Best Practices

### 1. Idempotency

Scripts must be safe to run multiple times:

```bash
# Good: Check before creating
if [ ! -d "$target_dir" ]; then
  mkdir -p "$target_dir"
fi

# Bad: Always creates
mkdir "$target_dir"  # Fails if exists
```

### 2. User Data Safety

Never overwrite user customizations:

```bash
# Good: Preserve existing
if [ ! -f "$user_config" ]; then
  cp "$default_config" "$user_config"
fi

# Bad: Always overwrites
cp "$default_config" "$user_config"
```

### 3. Variable Quoting

Always quote variables:

```bash
# Good
rm -rf "$target_dir"

# Bad - word splitting issues
rm -rf $target_dir
```

### 4. Error Handling

Handle errors gracefully:

```bash
if ! command_exists git; then
  log "Git is required but not installed"
  exit 1
fi
```

### 5. Logging

Use consistent logging:

```bash
log "Installing package..."
log "Configuration complete"
```

## Testing Your Plugin

### 1. Validate Structure

```bash
./plugins.sh validate plugins/my-awesome-plugin
```

### 2. Security Audit

```bash
./plugins.sh verify plugins/my-awesome-plugin
```

### 3. Test Installation

```bash
./plugins.sh install plugins/my-awesome-plugin
```

### 4. Test Activation/Deactivation

```bash
./plugins.sh activate my-awesome-plugin
./plugins.sh deactivate my-awesome-plugin
```

### 5. Test Uninstallation

```bash
./plugins.sh uninstall my-awesome-plugin
```

## Publishing Your Plugin

### Option 1: Local Distribution

Share your plugin directory. Users install with:

```bash
local_plugin '/path/to/my-awesome-plugin'
```

### Option 2: GitHub Repository

1. Create a GitHub repository for your plugin
2. Ensure all required files are present
3. Tag releases with semantic versions

Users install with:
```bash
plugin 'username/my-awesome-plugin'
```

Note: The plugin must be verified by Potions maintainers.

### Option 3: Submit to Official Registry

1. Fork the Potions repository
2. Add your plugin to `plugins/`
3. Run all validations
4. Submit a PR

## Checklist

Before publishing, ensure:

- [ ] `plugin.potions.json` has all required fields
- [ ] `install.sh` is executable and works on all platforms
- [ ] `uninstall.sh` properly cleans up
- [ ] `README.md` documents usage
- [ ] All scripts pass `bash -n` syntax check
- [ ] Security scan passes (`./plugins.sh verify`)
- [ ] Validation passes (`./plugins.sh validate`)
- [ ] Tested on at least one platform
- [ ] No hardcoded paths or credentials
- [ ] All variables are properly quoted
