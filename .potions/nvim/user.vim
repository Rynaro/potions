" User Neovim Configuration
" This file is preserved on upgrade - add your custom settings here
"
" Example: Add custom plugins
"   Plug 'your/plugin'
"
" Example: Custom keybindings
"   nnoremap <leader>xx :YourCommand<CR>
"
" Example: Custom settings
"   set relativenumber
"   set colorcolumn=80

" Theme Customization
" -------------------
" The Alchemists Orchid theme can be customized via:
"   ~/.potions/nvim/lua/theme/alchemists-orchid.lua
"
" After installing the plugin with:
"   ./plugins.sh install
"
" You can modify theme options like:
"   - transparent_background
"   - italic_comments
"   - custom highlight overrides

" ------------------------------------------------------------
" Optional augments (opt-in — uncomment to enable)
" ------------------------------------------------------------
" Centered scrolling — keep the cursor centered on jumps/search:
"   nnoremap <C-d> <C-d>zz
"   nnoremap <C-u> <C-u>zz
"   nnoremap n nzz
"   nnoremap N Nzz
"
" Surround text objects (requires a plugin in init.vim's plug block):
"   Plug 'kylechui/nvim-surround'   " then: lua require('nvim-surround').setup()
"   Usage: ys{motion}{char}  cs{old}{new}  ds{char}
