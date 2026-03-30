" ============================================================
" PLUGINS
" ============================================================

" Specify the directory for vim-plug
call plug#begin('~/.local/share/nvim/plugged')

" Essential plugins
Plug 'tpope/vim-sensible'        " Basic sensible settings for Vim

" Ruby-specific plugins
Plug 'vim-ruby/vim-ruby'         " Ruby syntax highlighting and indentation
Plug 'tpope/vim-rails'           " Ruby on Rails power tools
Plug 'tpope/vim-endwise'         " Automatically close Ruby blocks

" File tree explorer
Plug 'preservim/nerdtree'        " File tree explorer

" Syntax highlighting and navigation
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}

" Telescope for fuzzy finding
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim', {'tag': '0.1.6'}

" Additional plugins
Plug 'nvim-tree/nvim-web-devicons'
Plug 'lewis6991/gitsigns.nvim'
Plug 'romgrk/barbar.nvim'
Plug 'nvim-lualine/lualine.nvim'
Plug 'Rynaro/alchemists-orchid.nvim'

Plug 'mg979/vim-visual-multi', {'branch': 'master'} " Multiple cursors on editor
Plug 'lukas-reineke/indent-blankline.nvim' " Context Indent Lines
call plug#end()

" ============================================================
" SETTINGS
" ============================================================

" Add custom Lua path for theme configurations
lua << EOF
local potions_lua_path = vim.fn.expand('~/.potions/nvim/lua')
if vim.fn.isdirectory(potions_lua_path) == 1 then
  package.path = package.path .. ';' .. potions_lua_path .. '/?.lua'
  package.path = package.path .. ';' .. potions_lua_path .. '/?/init.lua'
end
EOF

" Basic settings
syntax on
set number
set tabstop=2
set shiftwidth=2
set expandtab
set guicursor=n-v-c:block,r-cr:hor20,o:hor50

" Better search highlighting
set hlsearch
set incsearch

" Set leader key to space (more ergonomic than backslash)
let mapleader = " "

" ============================================================
" THEME
" ============================================================

" Truecolor detection guard — only enable termguicolors when the terminal
" supports 24-bit color. This prevents text disappearance on terminals
" (e.g. Termux with $TERM='screen' or 'linux') that lack truecolor support.
if $COLORTERM == 'truecolor' || $COLORTERM == '24bit'
  set termguicolors
endif

" Load Alchemists Orchid theme configuration
" Theme preferences can be customized in ~/.potions/nvim/lua/theme/alchemists-orchid.lua
lua << EOF
local ok, theme_config = pcall(require, 'theme.alchemists-orchid')
if ok and theme_config.setup then
  theme_config.setup()
else
  -- Fallback: set colorscheme directly if config not found
  vim.cmd('colorscheme alchemists-orchid')
end
EOF

" Persist highlight overrides across colorscheme reloads via autocmd ColorScheme.
" Alchemists Orchid Papyrus palette reference (https://github.com/Rynaro/alchemists-orchid-papyrus)
" Full canonical token table: docs/color-palette.md
"   bg (surface.dark):     #1E1B2E  orchid-tinted deep dark   (color.surface.dark)
"   fg (secondary):        #E5D4F1  soft lavender white       (color.secondary / lavender.300)
"   primary:               #CDB4DB  orchid.500                (color.primary)
"   primary-deep:          #6F4A8E  orchid.700                (color.primary-deep)
"   accent.cool:           #B9C9E6  blue.400                  (color.accent.cool)
"   accent.nature:         #C8E7D5  mint.400                  (color.accent.nature)
"   accent.warm:           #F8D1E0  pink.400                  (color.accent.warm)
"   error:                 #D32F2F  input.border.error
"   muted-orchid:          #9E93B8  desaturated lavender
"   selection bg:          #44395a  deep orchid selection      (plugin-internal)
"   tab active bg:         #2d2640  slightly lighter dark       (plugin-internal)
"   tab fill bg:           #16121f  very dark purple            (plugin-internal)

augroup ThemeHighlights
  autocmd!
  autocmd ColorScheme * call s:SetThemeHighlights()
augroup END

function! s:SetThemeHighlights()
  " Visual mode selection — survives colorscheme reloads
  highlight Visual guifg=#e0d7f5 guibg=#44395a ctermfg=White ctermbg=DarkGrey

  " Barbar buffer tab highlights using Alchemists Orchid palette
  highlight BufferCurrent       guifg=#e0d7f5 guibg=#2d2640 gui=bold
  highlight BufferCurrentMod    guifg=#c678dd guibg=#2d2640 gui=bold
  highlight BufferInactive      guifg=#7a7094 guibg=#16121f
  highlight BufferInactiveMod   guifg=#c678dd guibg=#16121f
  highlight BufferTabpageFill   guibg=#16121f
endfunction

" Trigger immediately for the current colorscheme load
call s:SetThemeHighlights()

" Barbar Lua setup — explicit icon and separator configuration
lua << EOF
local ok, barbar = pcall(require, 'barbar')
if ok then
  barbar.setup({
    animation = true,
    auto_hide = false,
    tabpages = true,
    clickable = true,
    icons = {
      buffer_index = false,
      buffer_number = false,
      button = '',
      filetype = {
        custom_colors = false,
        enabled = true,
      },
      separator = { left = '▎', right = '' },
      separator_at_end = true,
      modified = { button = '●' },
      pinned = { button = '', filename = true },
      current = { buffer_index = true },
    },
    sidebar_filetypes = {
      NERDTree = true,
    },
  })
end
EOF

" ============================================================
" SHORTCUTS — Tier 1: Universal Ctrl (works everywhere)
" ============================================================
" Ctrl+s (save), Ctrl+n (NERDTree), Ctrl+c/v (copy/paste in visual)

" NERDTree toggle
nnoremap <silent> <C-n> :NERDTreeToggle<CR>

" Quick save (Ctrl+S - works with stty -ixon in terminal)
nnoremap <C-s> :w<CR>
inoremap <C-s> <C-o>:w<CR>
vnoremap <C-s> <Esc>:w<CR>

" Keybindings for copy, cut, and paste
vnoremap <silent> <C-c> "+y
vnoremap <silent> <C-x> "+d
nnoremap <silent> <C-v> "+p
inoremap <silent> <C-v> <C-r>+

" ============================================================
" SHORTCUTS — Tier 2: Leader (Space+key)
" ============================================================
" All navigation, buffer management, file ops, editing

" --- File / NERDTree ---
nnoremap <silent> <leader>nf :NERDTreeFind<CR>

" --- File path copy ---
nnoremap <silent> <leader>yr :let @+=expand('%')<CR>
nnoremap <silent> <leader>ya :let @+=expand('%:p')<CR>

" --- Search ---
nnoremap <silent> <leader><space> :noh<CR>
nnoremap <leader>/ *

" --- Select all ---
nnoremap <leader>a ggVG

" --- Quit / write ---
nnoremap <leader>q :q<CR>
nnoremap <leader>Q :q!<CR>
nnoremap <leader>w :w<CR>
nnoremap <leader>wq :wq<CR>

" --- Buffer navigation (leader-based, cross-platform reliable) ---
nnoremap <silent> <leader>h :BufferPrevious<CR>
nnoremap <silent> <leader>l :BufferNext<CR>
nnoremap <silent> <leader>H :BufferMovePrevious<CR>
nnoremap <silent> <leader>L :BufferMoveNext<CR>

" Tab / Shift-Tab cycle buffers in normal mode
" (insert-mode <S-Tab> for de-indent is preserved separately below)
nnoremap <Tab> :BufferNext<CR>
nnoremap <S-Tab> :BufferPrevious<CR>

" Direct buffer access by number
nnoremap <silent> <leader>1 :BufferGoto 1<CR>
nnoremap <silent> <leader>2 :BufferGoto 2<CR>
nnoremap <silent> <leader>3 :BufferGoto 3<CR>
nnoremap <silent> <leader>4 :BufferGoto 4<CR>
nnoremap <silent> <leader>5 :BufferGoto 5<CR>
nnoremap <silent> <leader>6 :BufferGoto 6<CR>
nnoremap <silent> <leader>7 :BufferGoto 7<CR>
nnoremap <silent> <leader>8 :BufferGoto 8<CR>
nnoremap <silent> <leader>9 :BufferGoto 9<CR>
nnoremap <silent> <leader>0 :BufferLast<CR>

" Buffer management
nnoremap <silent> <leader>bp :BufferPick<CR>
nnoremap <silent> <leader>bx :BufferPickDelete<CR>
nnoremap <silent> <leader>bi :BufferPin<CR>
nnoremap <silent> <leader>bc :BufferClose<CR>
nnoremap <silent> <leader>br :BufferRestore<CR>
nnoremap <silent> <Space>bb :BufferOrderByBufferNumber<CR>
nnoremap <silent> <Space>bn :BufferOrderByName<CR>
nnoremap <silent> <Space>bd :BufferOrderByDirectory<CR>
nnoremap <silent> <Space>bl :BufferOrderByLanguage<CR>
nnoremap <silent> <Space>bw :BufferOrderByWindowNumber<CR>

" --- Move lines (replaces unreliable Ctrl+Shift+Arrow and Ctrl+k/j) ---
nnoremap <leader>j :m .+1<CR>==
nnoremap <leader>k :m .-2<CR>==
vnoremap <leader>j :m '>+1<CR>gv=gv
vnoremap <leader>k :m '<-2<CR>gv=gv

" --- Navigation shortcuts (top/bottom of file) ---
nnoremap <silent> <leader>gg gg
nnoremap <silent> <leader>G G

" --- Insert mode de-indent (preserved; no conflict with normal-mode <S-Tab>) ---
inoremap <S-Tab> <C-d>

" ============================================================
" PLUGIN CONFIG
" ============================================================

" NERDTree settings
let NERDTreeShowHidden=1

" Automatically open NERDTree when starting nvim in a directory
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 1 && isdirectory(argv()[0]) && !exists('s:std_in') | exe 'NERDTree' argv()[0] | wincmd p | enew | exe 'cd '.argv()[0] | endif

" Define a custom highlight group for trailing whitespace
highlight ExtraWhitespace ctermbg=red guibg=red

" Function to match trailing whitespace
function! HighlightTrailingWhitespace()
  match ExtraWhitespace /\s\+$/
endfunction

" Autocommand to call the function on specific events
augroup HighlightTrailingWhitespace
  autocmd!
  autocmd BufWinEnter * call HighlightTrailingWhitespace()
  autocmd InsertLeave * call HighlightTrailingWhitespace()
  autocmd BufWritePre * call HighlightTrailingWhitespace()
  autocmd BufWritePost * call HighlightTrailingWhitespace()
  autocmd TextChanged * call HighlightTrailingWhitespace()
  autocmd VimEnter * call HighlightTrailingWhitespace()
augroup END

" vim-visual-multi keybindings
" <leader>d  — Find Under / start multi-cursor on word
" <leader>D  — Select All occurrences (replaces removed <C-S-l>)
" <leader>x  — Skip Region
" <leader>X  — Remove Region (replaces removed <C-S-k>)
" Add Cursor Down/Up (<C-S-Down>/<C-S-Up>) removed entirely;
"   use repeated <leader>d as the workflow instead.
let g:VM_maps = {}
let g:VM_maps['Find Under']         = '<leader>d'
let g:VM_maps['Find Subword Under'] = '<leader>d'
let g:VM_maps['Select All']         = '<leader>D'
let g:VM_maps['Skip Region']        = '<leader>x'
let g:VM_maps['Remove Region']      = '<leader>X'

" Neovim 0.10+ compatibility: restore ft_to_lang removed from treesitter API
lua << EOF
if vim.treesitter.language and not vim.treesitter.language.ft_to_lang then
  vim.treesitter.language.ft_to_lang = function(ft)
    return vim.treesitter.language.get_lang(ft) or ft
  end
end
EOF

" Telescope configuration and keybindings
" Uses pcall to gracefully handle case when plugin isn't installed yet
lua << EOF
local ok, telescope = pcall(require, 'telescope')
if ok then
  local builtin = require('telescope.builtin')

  vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
  vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
  vim.keymap.set('n', '<leader>fb', builtin.buffers, {})
  vim.keymap.set('n', '<leader>fh', builtin.help_tags, {})
  vim.keymap.set('n', '<leader>fs', builtin.git_status, {})
  vim.keymap.set('n', '<leader>fc', builtin.git_commits, {})
  vim.keymap.set('n', '<leader>fr', builtin.lsp_references, {})
  vim.keymap.set('n', '<leader>fd', builtin.lsp_definitions, {})

  telescope.setup{
    defaults = {},
    pickers = {},
    extensions = {},
  }
end
EOF

" Lualine configuration
" Uses pcall to gracefully handle case when plugin isn't installed yet
lua << END
local ok, lualine = pcall(require, 'lualine')
if ok then
  lualine.setup()
end
END

" Indent Blank Line Settings
" Uses pcall to gracefully handle case when plugin isn't installed yet
lua << EOF
local ok, ibl = pcall(require, 'ibl')
if ok then
  ibl.setup()
end
EOF

" Treesitter configuration for better syntax highlighting and navigation
" Uses pcall to gracefully handle case when plugin isn't installed yet
lua << EOF
local ok, treesitter_configs = pcall(require, 'nvim-treesitter.configs')
if ok then
  treesitter_configs.setup {
    highlight = {
      enable = true,
    },
    indent = {
      enable = true,
    },
    incremental_selection = {
      enable = true,
      keymaps = {
        init_selection = "gnn",
        node_incremental = "grn",
        scope_incremental = "grc",
        node_decremental = "grm",
      },
    },
    textobjects = {
      select = {
        enable = true,
        lookahead = true,
        keymaps = {
          ["af"] = "@function.outer",
          ["if"] = "@function.inner",
        },
      },
      move = {
        enable = true,
        set_jumps = true,
        goto_next_start = {
          ["]m"] = "@function.outer",
        },
        goto_previous_start = {
          ["[m"] = "@function.outer",
        },
      },
    },
    rainbow = {
      enable = true,
      extended_mode = true,
      max_file_lines = nil,
    },
  }
end
EOF

" ============================================================
" USER OVERRIDES
" ============================================================

" User customizations - this file is preserved on upgrade
" Add your personal plugins and settings in ~/.potions/nvim/user.vim
if filereadable(expand("~/.potions/nvim/user.vim"))
  source ~/.potions/nvim/user.vim
endif
