-- Alchemists Orchid Theme Configuration
-- This file is preserved on plugin upgrades
-- Customize your theme preferences here

local M = {}

-- Theme variant options (if supported by theme)
M.variant = "default"  -- Options: "default", "dark", "light" (if available)

-- Enable/disable specific features
M.options = {
  transparent_background = false,
  italic_comments = true,
  italic_keywords = false,
  bold_functions = true,
}

-- Custom highlight overrides
-- Example: M.overrides = { Comment = { fg = "#7c7c7c" } }
M.overrides = {}

-- Setup function called by init.vim
M.setup = function()
  local ok, theme = pcall(require, 'alchemists-orchid')
  if ok then
    -- Apply configuration if theme supports setup function
    if theme.setup then
      theme.setup(M.options)
    end

    -- Set colorscheme
    vim.cmd('colorscheme alchemists-orchid')

    -- Apply custom overrides
    for group, settings in pairs(M.overrides) do
      vim.api.nvim_set_hl(0, group, settings)
    end
  end
end

return M
