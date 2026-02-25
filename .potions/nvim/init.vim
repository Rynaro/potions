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

" Set leader key to space (more ergonomic than backslash)
let mapleader = " "

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

" Force custom visual mode selection colors (can be overridden in theme config)
highlight Visual ctermfg=White ctermbg=DarkGrey guifg=White guibg=DarkGrey

" NERDTree settings
nnoremap <silent> <C-n> :NERDTreeToggle<CR>
nnoremap <silent> <leader>nf :NERDTreeFind<CR>
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

" Key mapping to copy the opened file relative path
nnoremap <silent> <leader>yr :let @+=expand('%')<CR>

" Key mapping to copy the opened file absolute path
nnoremap <silent> <leader>ya :let @+=expand('%:p')<CR>

" Move to the beginning of the line (macOS-friendly: Ctrl+A)
nnoremap <C-a> ^
inoremap <C-a> <C-o>^
vnoremap <C-a> ^

" Move to the end of the line (macOS-friendly: Ctrl+E)
nnoremap <C-e> $
inoremap <C-e> <C-o>$
vnoremap <C-e> $

" Moving to the Previous Paragraph (Ctrl+{)
nnoremap <C-{> {

" Moving to the Next Paragraph (Ctrl+})
nnoremap <C-}> }

" Keybindings for large line movements and navigation
nnoremap <C-u> 10k
nnoremap <C-d> 10j
nnoremap <silent> <leader>gg gg
nnoremap <silent> <leader>G G

" Better search highlighting
set hlsearch
set incsearch
nnoremap <silent> <leader><space> :noh<CR>  " Clear search highlight
nnoremap <leader>/ *  " Search for word under cursor

" Keybindings for copy, cut, and paste
vnoremap <silent> <C-c> "+y
vnoremap <silent> <C-x> "+d
nnoremap <silent> <C-v> "+p
inoremap <silent> <C-v> <C-r>+

" Keybindings for moving lines up and down (macOS-friendly: Ctrl+Shift+Arrow)
nnoremap <C-S-Up> :m .-2<CR>==
nnoremap <C-S-Down> :m .+1<CR>==
xnoremap <C-S-Up> :m '<-2<CR>gv=gv
xnoremap <C-S-Down> :m '>+1<CR>gv=gv
" Alternative: Ctrl+k/j for moving lines (more reliable on macOS)
nnoremap <C-k> :m .-2<CR>==
nnoremap <C-j> :m .+1<CR>==
xnoremap <C-k> :m '<-2<CR>gv=gv
xnoremap <C-j> :m '>+1<CR>gv=gv

" Key mapping for select all file content while in Visual Mode
nnoremap <leader>a ggVG

" Quick save (Ctrl+S - works with stty -ixon in terminal)
nnoremap <C-s> :w<CR>
inoremap <C-s> <C-o>:w<CR>
vnoremap <C-s> <Esc>:w<CR>

" Quick quit (without saving)
nnoremap <leader>q :q<CR>
nnoremap <leader>Q :q!<CR>
nnoremap <leader>w :w<CR>
nnoremap <leader>wq :wq<CR>

" Key mapping to move tab back in insert mode with Shift+Tab
inoremap <S-Tab> <C-d>

" Barbar keybindings for buffer management (macOS-friendly: Ctrl+Shift based)
nnoremap <silent> <C-S-h> :BufferPrevious<CR>
nnoremap <silent> <C-S-l> :BufferNext<CR>
nnoremap <silent> <C-S-H> :BufferMovePrevious<CR>
nnoremap <silent> <C-S-L> :BufferMoveNext<CR>
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
" Buffer management - using leader keys to avoid conflicts
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

" vim-visual-multi keybindings for VSCode-like multi-cursor editing
" Using leader-based bindings to avoid conflicts with scroll and buffer commands
" See KEYMAPS.md for full conflict resolution documentation
let g:VM_maps = {}
let g:VM_maps['Find Under']         = '<leader>d'   " Start multi-cursor on word (was Ctrl+D)
let g:VM_maps['Find Subword Under'] = '<leader>d'   " Start multi-cursor on subword
let g:VM_maps['Select All']         = '<C-S-l>'     " Select all occurrences
let g:VM_maps['Skip Region']        = '<leader>x'   " Skip current occurrence (was Ctrl+X)
let g:VM_maps['Remove Region']      = '<C-S-k>'     " Remove current cursor
let g:VM_maps['Add Cursor Down']    = '<C-S-Down>'  " Add cursor down
let g:VM_maps['Add Cursor Up']      = '<C-S-Up>'    " Add cursor up

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

" User customizations - this file is preserved on upgrade
" Add your personal plugins and settings in ~/.potions/nvim/user.vim
if filereadable(expand("~/.potions/nvim/user.vim"))
  source ~/.potions/nvim/user.vim
endif
