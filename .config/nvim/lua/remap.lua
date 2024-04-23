vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')
vim.api.nvim_set_keymap("n", "F", "$", {})
vim.api.nvim_set_keymap("n", "S", "^", {})
vim.keymap.set("n", "<leader><leader>", function() vim.cmd("so") end, {})
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = 'Go to previous [D]iagnostic message' })
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = 'Go to next [D]iagnostic message' })
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })
vim.api.nvim_set_keymap('n', 't', ':terminal<CR>i',{})

--Shift commands:
vim.keymap.set('n', '<S-q>', '<cmd>:wq<CR>')
vim.api.nvim_set_keymap("n", "<S-w>", ":w<CR>", {})
vim.keymap.set('n', '<S-e>', vim.diagnostic.open_float, { desc = 'Show diagnostic [E]rror messages' })
vim.keymap.set("n", "m", "mzJ`z")
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

--leader commands:
vim.keymap.set('n', '<leader>e', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })
vim.keymap.set("x", "<leader>p", [["_dP]])
--vim.keymap.set("n", "<leader>f", vim.lsp.buf.format)
vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])
vim.keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true })
vim.keymap.set("n", "<leader>k", "<cmd>lnext<CR>zz")
vim.keymap.set("n", "<leader>j", "<cmd>lprev<CR>zz")

--command commands:
vim.keymap.set("n", "<C-k>", "<cmd>cnext<CR>zz")
vim.keymap.set("n", "<C-j>", "<cmd>cprev<CR>zz")
vim.api.nvim_set_keymap('n', '<C-f>', ':!tmux select-window -t 1 && tmux send-keys C-f<CR>', {noremap = true, silent = true})


--vim.api.nvim_set_keymap("n", "'", ":Oil<CR>", {})
--vim.api.nvim_set_keymap("n", "<C-p>", ":MarkdownPreviewToggle<CR>", {})
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- Panes:
vim.api.nvim_set_keymap('n', '<C-b>', ':split<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<C-n>', ':vsplit<CR>', { noremap = true, silent = true })

vim.api.nvim_set_keymap('n', '<C-J>', '<C-w>j', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<C-K>', '<C-w>k', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<C-L>', '<C-w>l', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<C-H>', '<C-w>h', { noremap = true, silent = true })

