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

" Basic settings
syntax on
set number
set tabstop=2
set shiftwidth=2
set expandtab
set guicursor=n-v-c:block,r-cr:hor20,o:hor50

" Set colorscheme
colorscheme alchemists-orchid
" Force custom visual mode selection colors
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

" Move to the beginning of the line Ctrl+Alt+Left
nnoremap <S-A-Left> ^
inoremap <S-A-Left> <C-o>^
vnoremap <S-A-Left> ^

" Move to the end of the line Ctrl+Alt+Right
nnoremap <S-A-Right> $
inoremap <S-A-Right> <C-o>$
vnoremap <S-A-Right> $

" Moving to the Previous Paragraph (Ctrl+Alt+Up)
nnoremap <C-A-Up> {

" Moving to the Next Paragraph (Ctrl+Alt+Down)
nnoremap <C-A-Down> }

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

" Key mapping for select all file content while in Visual Mode
nnoremap <leader>a ggVG

" Key mapping to move tab back in insert mode with Shift+Tab
inoremap <S-Tab> <C-d>

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

" Indent Blank Line Settings
lua << EOF
require("ibl").setup()
EOF

" Treesitter configuration for better syntax highlighting and navigation
lua << EOF
require'nvim-treesitter.configs'.setup {
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
    extended_mode = true, -- Highlight also non-parentheses delimiters
    max_file_lines = nil, -- Do not limit number of lines
  },
}
EOF
