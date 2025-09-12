let mapleader = " "

" Use system clipboard
set clipboard=unnamedplus

" Wrapping
set wrap

" Indentation
set tabstop=2
set shiftwidth=2
set smartindent

" Search
set hlsearch
set incsearch
set ignorecase

" Remove highlight
nnoremap <C-c> :noh<CR>

" File operations
nnoremap <leader><leader> :write<CR>

" Buffer navigation
nnoremap <leader>s :e #<CR>
nnoremap <leader>S :sf #<CR>

" Spell check
nnoremap <leader>c 1z=
vnoremap <leader>c 1z=

" Start and End of Line
nnoremap H ^
nnoremap L $

" Move line up or down (visual mode)
vnoremap J :m '>+1<CR>gv=gv
vnoremap K :m '<-2<CR>gv=gv

" Move half a screen up/down and center
nnoremap J <C-d>zz
nnoremap K <C-u>zz

" Join the line below with the one above
nnoremap m mzJ`z
