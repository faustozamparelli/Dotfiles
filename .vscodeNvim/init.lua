vim.g.mapleader = ' '
vim.keymap.set('n', 'U', '<C-r>')
vim.o.clipboard = "unnamedplus"
vim.api.nvim_set_keymap("n", "H", "^", {})
vim.api.nvim_set_keymap("n", "L", "$", {})
vim.o.incsearch = true
vim.o.ignorecase = true
vim.api.nvim_set_keymap("n", "<leader>z", ":nohlsearch<CR>", { noremap = true, silent = true })
