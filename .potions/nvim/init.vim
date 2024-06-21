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
Plug 'arcticicestudio/nord-vim'

Plug 'mg979/vim-visual-multi', {'branch': 'master'} " Multiple cursors on editor

call plug#end()

" Basic settings
syntax on
set number
set tabstop=2
set shiftwidth=2
set expandtab

" Set colorscheme
colorscheme nord

" NERDTree settings
nnoremap <silent> <C-n> :NERDTreeToggle<CR>
let NERDTreeShowHidden=1

" Automatically open NERDTree when starting nvim in a directory
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 1 && isdirectory(argv()[0]) && !exists('s:std_in') | exe 'NERDTree' argv()[0] | wincmd p | enew | exe 'cd '.argv()[0] | endif

" Function to ensure a file ends with a newline
function! EnsureTrailingNewline()
  " Get the last character of the file
  let l:last_char = getline('$')[-1:]
  " Check if the last character is not a newline
  if l:last_char != "\n"
    " Add a newline at the end of the file
    normal! Go
  endif
endfunction

" Autocommand to call the function before saving a file
augroup EnsureTrailingNewline
  autocmd!
  autocmd BufWritePre * call EnsureTrailingNewline()
augroup END

" Barbar keybindings for buffer management
nnoremap <silent> <A-,> :BufferPrevious<CR>
nnoremap <silent> <A-.> :BufferNext<CR>
nnoremap <silent> <A-<> :BufferMovePrevious<CR>
nnoremap <silent> <A->> :BufferMoveNext<CR>
nnoremap <silent> <A-1> :BufferGoto 1<CR>
nnoremap <silent> <A-2> :BufferGoto 2<CR>
nnoremap <silent> <A-3> :BufferGoto 3<CR>
nnoremap <silent> <A-4> :BufferGoto 4<CR>
nnoremap <silent> <A-5> :BufferGoto 5<CR>
nnoremap <silent> <A-6> :BufferGoto 6<CR>
nnoremap <silent> <A-7> :BufferGoto 7<CR>
nnoremap <silent> <A-8> :BufferGoto 8<CR>
nnoremap <silent> <A-9> :BufferGoto 9<CR>
nnoremap <silent> <A-0> :BufferLast<CR>
nnoremap <silent> <A-p> :BufferPin<CR>
nnoremap <silent> <A-c> :BufferClose<CR>
nnoremap <silent> <A-s-c> :BufferRestore<CR>
nnoremap <silent> <C-p> :BufferPick<CR>
nnoremap <silent> <C-x> :BufferPickDelete<CR>
nnoremap <silent> <Space>bb :BufferOrderByBufferNumber<CR>
nnoremap <silent> <Space>bn :BufferOrderByName<CR>
nnoremap <silent> <Space>bd :BufferOrderByDirectory<CR>
nnoremap <silent> <Space>bl :BufferOrderByLanguage<CR>
nnoremap <silent> <Space>bw :BufferOrderByWindowNumber<CR>

" Keybindings for large line movements and navigation
nnoremap <C-u> 10k
nnoremap <C-d> 10j
nnoremap <silent> <leader>gg gg
nnoremap <silent> <leader>G G

" Keybindings for copy, cut, and paste
vnoremap <silent> <C-c> "+y
vnoremap <silent> <C-x> "+d
nnoremap <silent> <C-v> "+p
inoremap <silent> <C-v> <C-r>+

" Keybindings for moving lines up and down
nnoremap <A-k> :m .-2<CR>==
nnoremap <A-j> :m .+1<CR>==
xnoremap <A-k> :m '<-2<CR>gv=gv
xnoremap <A-j> :m '>+1<CR>gv=gv

" vim-visual-multi keybindings for VSCode-like multi-cursor editing
let g:VM_maps = {}
let g:VM_maps['Find Under']         = '<C-d>'  " Start multi-cursor (similar to VSCode's Ctrl+D)
let g:VM_maps['Find Subword Under'] = '<C-d>'  " Start multi-cursor (similar to VSCode's Ctrl+D)
let g:VM_maps['Select All']         = '<C-S-L>'  " Select all occurrences (similar to VSCode's Ctrl+Shift+L)
let g:VM_maps['Skip Region']        = '<C-x>'  " Skip current occurrence
let g:VM_maps['Remove Region']      = '<C-S-k>'  " Remove current cursor (similar to VSCode's Ctrl+U)
let g:VM_maps['Add Cursor Down']    = '<A-Down>'  " Add cursor down (similar to VSCode's Alt+Down)
let g:VM_maps['Add Cursor Up']      = '<A-Up>'    " Add cursor up (similar to VSCode's Alt+Up)

" Telescope configuration and keybindings
lua << EOF
local builtin = require('telescope.builtin')

vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
vim.keymap.set('n', '<leader>fb', builtin.buffers, {})
vim.keymap.set('n', '<leader>fh', builtin.help_tags, {})

require('telescope').setup{
  defaults = {
    -- Default configuration for Telescope goes here:
    -- config_key = value,
  },
  pickers = {
    -- Default configuration for builtin pickers goes here:
    -- picker_name = {
    --   picker_config_key = value,
    --   ...
    -- },
  },
  extensions = {
    -- Your extension configuration goes here:
    -- extension_name = {
    --   extension_config_key = value,
    -- }
  },
}
EOF

" Lualine configuration
lua << END
require('lualine').setup()
END

" Treesitter configuration for better syntax highlighting and navigation
lua << EOF
require'nvim-treesitter.configs'.setup {
  highlight = {
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
}
EOF
