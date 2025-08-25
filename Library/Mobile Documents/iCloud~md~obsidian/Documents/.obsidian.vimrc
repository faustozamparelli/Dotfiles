" Use system clipboard
set clipboard=unnamedplus

" Remove highlight
nnoremap <C-c> :noh<CR>

" Map U to redo
nnoremap U <C-r>

" Start and End of Line
nnoremap H ^
nnoremap L $

" Move half a screen up/down and center
nnoremap J <C-d>zz
nnoremap K <C-u>zz

" Join the line below with the one above
nnoremap m mzJ`z
