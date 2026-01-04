# Potions Plugin System

A powerful, secure, and easy-to-use plugin system for extending Potions functionality.

## Overview

The Potions plugin system allows you to:
- Install verified plugins from the [Potions Shelf Registry](https://github.com/Rynaro/potions-shelf)
- Create and use your own local plugins
- Manage plugin lifecycle (install, uninstall, activate, deactivate)
- Extend NeoVim, shell, and tmux configurations
- Search and discover plugins from the official registry

## Quick Start

### Installing Plugins

1. Add plugins to your `~/.potions/Potionfile`:

```bash
# Official verified plugins
plugin 'orchid-flask'

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

Remote plugins are fetched from the [Potions Shelf Registry](https://github.com/Rynaro/potions-shelf), a GitHub-hosted registry that provides:
- Automated validation and security scanning
- Easy plugin discovery via search
- Manifest-based plugin definitions (.potion format)
- Dependency resolution
- Checksum verification

Plugins in the registry are verified to ensure:
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
# Create plugin with JSON manifest (default)
./plugins.sh create my-awesome-plugin

# Create plugin with YAML manifest (.potion format for registry)
./plugins.sh create my-awesome-plugin --potion
```

This creates:
```
plugins/my-awesome-plugin/
├── plugin.potions.json    # Plugin manifest (JSON) OR
├── .potion                # Plugin manifest (YAML, if --potion used)
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

**Note:** Use `--potion` flag to generate a YAML manifest (.potion format) which is required for submission to the Potions Shelf Registry.

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
plugin 'orchid-flask'

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

## Registry Management

### Sync Registry Cache

```bash
# Manually sync the registry cache
./plugins.sh registry-sync

# Check registry connection status
./plugins.sh registry-status
```

The registry cache is automatically updated when needed (every 24 hours by default).

### Search Plugins

```bash
# List all available plugins
./plugins.sh search

# Search for specific plugins
./plugins.sh search docker
./plugins.sh search theme
```

## Contributing Plugins

To add your plugin to the [Potions Shelf Registry](https://github.com/Rynaro/potions-shelf):

1. Create your plugin with `--potion` flag: `./plugins.sh create my-plugin --potion`
2. Ensure your plugin follows the structure above
3. Run validation: `./plugins.sh validate my-plugin`
4. Submit a PR to the [potions-shelf repository](https://github.com/Rynaro/potions-shelf) with your `.potion` manifest
5. The registry's automated validation will verify your plugin
6. Once approved, your plugin will be available to all Potions users

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
