# Potions Plugin System

A powerful, secure, and easy-to-use plugin system for extending Potions functionality.

## Overview

The Potions plugin system allows you to:
- Install verified plugins from the Potions registry
- Create and use your own local plugins
- Manage plugin lifecycle (install, uninstall, activate, deactivate)
- Extend NeoVim, shell, and tmux configurations

## Quick Start

### Installing Plugins

1. Add plugins to your `~/.potions/Potionfile`:

```bash
# Official verified plugins
plugin 'alchemists-orchid'

# GitHub repos (must be verified)
plugin 'Rynaro/potions-docker', tag: 'v1.0.0'

# Local plugins (your own)
local_plugin '~/my-plugins/custom-theme'
```

2. Install all plugins:

```bash
potions plugin install
# or
./plugins.sh install
```

### Managing Plugins

```bash
# List installed plugins
potions plugin list

# Show plugin status
potions plugin status

# Activate/deactivate a plugin
potions plugin activate my-plugin
potions plugin deactivate my-plugin

# Update plugins
potions plugin update

# Uninstall a plugin
potions plugin uninstall my-plugin
```

## Plugin Types

### Verified Plugins (Remote)

Remote plugins must be in the verified Potions registry. This ensures:
- Code has been reviewed by Potions maintainers
- No malicious patterns detected
- Follows Potions coding standards
- Safe for all users

### Local Plugins

Your own plugins that bypass verification:
- Perfect for development and testing
- Can be symlinked for easy development
- Warning displayed during installation

## Creating Plugins

### Scaffold a New Plugin

```bash
./plugins.sh create my-awesome-plugin
```

This creates:
```
plugins/my-awesome-plugin/
├── plugin.potions.json    # Plugin manifest
├── install.sh             # Installation script
├── uninstall.sh           # Uninstallation script
├── activate.sh            # Activation script
├── deactivate.sh          # Deactivation script
├── utilities.sh           # Helper functions
├── packages/              # Package scripts
│   └── main.sh
├── config/                # Configuration files
│   └── init.zsh
└── README.md              # Documentation
```

### Plugin Manifest

Every plugin must have a `plugin.potions.json`:

```json
{
  "name": "my-plugin",
  "version": "1.0.0",
  "description": "A cool Potions plugin",
  "author": "Your Name",
  "license": "MIT",
  "potions_min_version": "2.6.0",
  "platforms": ["macos", "linux", "wsl", "termux"],
  "dependencies": [],
  "provides": {
    "nvim": ["colorscheme"],
    "shell": ["aliases", "functions"],
    "tmux": []
  }
}
```

### Required Files

| File | Description |
|------|-------------|
| `plugin.potions.json` | Plugin manifest with metadata |
| `install.sh` | Installation script |
| `uninstall.sh` | Uninstallation script |
| `README.md` | Plugin documentation |

### Optional Files

| File | Description |
|------|-------------|
| `activate.sh` | Activation script |
| `deactivate.sh` | Deactivation script |
| `utilities.sh` | Helper functions |
| `packages/*.sh` | Package installation scripts |
| `config/*.zsh` | Shell configurations |
| `config/*.lua` | NeoVim configurations |

## Security Model

| Plugin Type | Verification | Security Scan | Allowed From |
|-------------|--------------|---------------|--------------|
| Verified Remote | Full checksum | Yes | verified.txt only |
| Local | None (warning shown) | Optional | User's filesystem |
| Unverified Remote | **REJECTED** | N/A | Not allowed |

### Security Scans

Plugins are scanned for:
- Remote code execution patterns (`curl | bash`)
- Code injection risks (`eval` with variables)
- Dangerous file operations (`rm -rf /`)
- Hardcoded credentials
- Unquoted variables in critical paths

Run a security audit:
```bash
./plugins.sh verify my-plugin
```

## Configuration Files

### Potionfile

Located at `~/.potions/Potionfile`, declares which plugins to install:

```bash
# Plugin from registry
plugin 'alchemists-orchid'

# Plugin from GitHub with specific version
plugin 'Rynaro/potions-docker', tag: 'v2.0.0'

# Local plugin
local_plugin '~/my-plugins/custom'
```

### Potionfile.lock

Auto-generated lockfile tracking installed versions:
```
plugin-name|version|checksum|source
```

### State File

Located at `~/.potions/plugins/.state`, tracks plugin activation state.

## CLI Commands

| Command | Description |
|---------|-------------|
| `install [plugin]` | Install from Potionfile or specific plugin |
| `uninstall <plugin>` | Uninstall a plugin |
| `activate <plugin>` | Activate an installed plugin |
| `deactivate <plugin>` | Deactivate without uninstalling |
| `update [plugin]` | Update all or specific plugin |
| `list [--active\|--inactive]` | List installed plugins |
| `status` | Show plugin system status |
| `search [query]` | Search available plugins |
| `info <plugin>` | Show plugin details |
| `create <name>` | Scaffold new plugin |
| `verify <plugin>` | Run security audit |
| `validate <plugin>` | Validate plugin structure |
| `regenerate-init` | Regenerate init script |
| `clean` | Clean orphaned entries |

## Plugin Loading

Active plugins are loaded at shell startup via `~/.potions/plugins/.init.zsh`. This file is auto-generated and sources:
- Shell configurations from `config/*.zsh`
- Shell configurations from `config/*.sh`

## Contributing Plugins

To add your plugin to the verified registry:

1. Ensure your plugin follows the structure above
2. Run validation: `./plugins.sh validate your-plugin`
3. Submit a PR to the Potions repository
4. Maintainer will review and verify your plugin

## Migration

If you have old-style plugins, run the migration script:

```bash
./plugins/migrate_plugins.sh
```

This will:
- Generate `plugin.potions.json` manifests
- Create missing required files
- Migrate `plugins.txt` to `Potionfile`

## Troubleshooting

### Plugin not loading

1. Check if plugin is active: `potions plugin list --active`
2. Regenerate init script: `potions plugin regenerate-init`
3. Restart your shell

### Installation fails

1. Check if plugin is verified: `potions plugin info plugin-name`
2. For local plugins, ensure path is correct
3. Run validation: `./plugins.sh validate plugin-name`

### Security scan fails

Review the scan output and fix any issues. For false positives in local plugins, use `--skip-security` flag (not recommended for shared plugins).
