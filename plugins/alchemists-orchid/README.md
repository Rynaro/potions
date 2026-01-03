# Alchemists Orchid Theme Plugin

A Potions plugin for managing the Alchemist's Orchid NeoVim colorscheme with customizable preferences.

## Description

This plugin integrates the beautiful Alchemist's Orchid colorscheme into your Potions-managed NeoVim setup. It provides:

- Automatic theme installation via vim-plug
- Customizable theme options
- Persistent configuration that survives upgrades

## Requirements

- Potions v2.6.0 or later
- NeoVim with vim-plug installed
- Lua support in NeoVim

## Installation

### Via Potionfile (Recommended)

Add to your `~/.potions/Potionfile`:

```bash
plugin 'alchemists-orchid'
```

Then run:

```bash
potions plugin install
```

### Manual Installation

```bash
./plugins.sh install alchemists-orchid
```

After installation, run `:PlugInstall` in NeoVim to download the theme.

## Configuration

After installation, customize your theme in:

```
~/.potions/nvim/lua/theme/alchemists-orchid.lua
```

### Available Options

```lua
M.options = {
  transparent_background = false,  -- Enable transparent background
  italic_comments = true,          -- Italicize comments
  italic_keywords = false,         -- Italicize keywords
  bold_functions = true,           -- Bold function names
}
```

### Theme Variants

```lua
M.variant = "default"  -- Options: "default", "dark", "light" (if available)
```

### Custom Highlight Overrides

```lua
M.overrides = {
  Comment = { fg = "#7c7c7c", italic = true },
  -- Add more overrides as needed
}
```

## Usage

The theme is automatically applied when NeoVim starts. The configuration file provides a `setup()` function that:

1. Loads the theme with your options
2. Sets the colorscheme
3. Applies any custom highlight overrides

## Managing the Plugin

```bash
# Activate the theme
potions plugin activate alchemists-orchid

# Deactivate the theme
potions plugin deactivate alchemists-orchid

# Uninstall the plugin
potions plugin uninstall alchemists-orchid
```

## Theme Repository

- GitHub: https://github.com/Rynaro/alchemists-orchid.nvim

## Uninstallation

```bash
potions plugin uninstall alchemists-orchid
```

Note: User configurations at `~/.potions/nvim/lua/theme/alchemists-orchid.lua` are preserved. Remove manually if no longer needed.

## License

MIT

## Author

Rynaro (Henrique A. Lavezzo)
