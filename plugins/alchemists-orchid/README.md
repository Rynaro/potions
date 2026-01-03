# Alchemists Orchid Theme Plugin

A Potions plugin for managing the Alchemists Orchid NeoVim colorscheme with customizable preferences.

## Installation

```bash
# Add to plugins.txt (create if doesn't exist)
echo "Rynaro/potions-alchemists-orchid" >> plugins.txt

# Install the plugin
./plugins.sh install
```

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

### Custom Highlight Overrides

```lua
M.overrides = {
  Comment = { fg = "#7c7c7c", italic = true },
  -- Add more overrides as needed
}
```

## Theme Repository

- GitHub: https://github.com/Rynaro/alchemists-orchid.nvim
