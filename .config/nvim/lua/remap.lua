vim.g.mapleader = " "
vim.o.timeoutlen = 10000
vim.o.clipboard = "unnamedplus"
vim.opt.expandtab = true
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.cmd([[highlight WinSeparator guibg=None]])
vim.cmd([[set laststatus=3]])
vim.opt.relativenumber = true
vim.api.nvim_set_keymap("n", "<leader>z", ":nohlsearch<CR>", { noremap = true, silent = true })
vim.cmd([[highlight Comment ctermfg=Gray]])
vim.cmd([[highlight SignColumn ctermbg=NONE]])
vim.api.nvim_set_keymap("i", "jj", "<Esc>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<leader>w", ":w<CR>", {})
vim.api.nvim_set_keymap("n", "'", ":Oil<CR>", {})
vim.api.nvim_set_keymap("n", "<C-p>", ":MarkdownPreviewToggle<CR>", {})
--vim.wo.foldlevel = 99
vim.wo.conceallevel = 0
vim.api.nvim_set_keymap("n", "H", "^", {})
vim.api.nvim_set_keymap("n", "L", "$", {})
vim.cmd('set splitright')
vim.keymap.set('n', 'U', '<C-r>')
vim.o.incsearch = true
vim.o.ignorecase = true

--easyallign
vim.api.nvim_set_keymap('x', 'ga', '<Plug>(EasyAlign)', {})

vim.opt.backup = false
vim.opt.writebackup = false
