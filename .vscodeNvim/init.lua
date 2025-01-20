vim.o.shell = "/opt/homebrew/bin/fish"
vim.cmd([[autocmd VimEnter,VimLeave * silent !tmux set status]])
vim.g.mapleader = " "
vim.opt.clipboard = "unnamedplus"
-- vim.opt.relativenumber = true
vim.opt.mouse = ""
-- vim.opt.showmode = false
-- vim.opt.wrap = false
-- vim.opt.tabstop = 4
-- vim.opt.softtabstop = 4
-- vim.opt.shiftwidth = 4
-- vim.opt.expandtab = true
-- vim.opt.smartindent = true
-- vim.opt.breakindent = true
 vim.opt.ignorecase = true
 vim.opt.smartcase = true
 vim.opt.splitright = true
-- vim.opt.updatetime = 2000
-- vim.opt.timeoutlen = 300
-- vim.opt.splitbelow = true
-- vim.opt.inccommand = "split"
-- vim.opt.scrolloff = 15
 vim.opt.cursorline = true
-- vim.opt.signcolumn = "yes"
 vim.o.hlsearch = true
 vim.o.incsearch = true
-- vim.opt.backup = false
-- vim.opt.swapfile = false
-- vim.opt.writebackup = false
-- vim.opt.list = true
-- vim.opt.listchars = { tab = "| ", trail = "·", nbsp = "␣" }
-- vim.cmd([[set laststatus=3]])
-- vim.cmd([[cnoremap <Down> <C-n>]])
-- vim.cmd([[cnoremap <Up> <C-p>]])
--
-- vim.cmd([[autocmd BufRead,BufWrite ~/.config/nvim/notes/* set nobuflisted bufhidden=wipe]])
-- vim.cmd([[autocmd VimEnter * if argc() == 0 | call luaeval('require("nvim-possession").list()') | endif ]])

vim.wo.foldlevel = 99
vim.wo.foldmethod = "expr"
vim.wo.foldexpr = "nvim_treesitter#foldexpr()"
local set = vim.keymap.set

-- -- dismiss copilot suggestions
-- set("i", "<C-c>", "<plug>(copilot-dismiss)<C-c>", { silent = true })

-- -- end/start of line
set("n", "F", "$", { silent = true })
set("n", "S", "^", { silent = true })

-- -- previous/next diagnostic
-- set("n", "[d", vim.diagnostic.goto_prev, { silent = true })
-- set("n", "]d", vim.diagnostic.goto_next, { silent = true })

-- --open terminal and get out of insert mode
-- set("n", "<leader>t", ":term<CR>i", { silent = true })
-- set("t", "<Esc><Esc>", "<C-\\><C-n>", { silent = true })

-- -- quit the file and close tmux window
-- set("n", "<C-w>", "<cmd>:w<CR>:silent !tmux kill-window<CR>", { silent = true })

-- -- close the current buffer
-- set("n", "<S-q>", "<cmd>:w<CR>:bd<CR>", { silent = true })

-- -- reload the file
-- set("n", "<S-w>", ":w | so<CR>", { silent = true })

-- -- join the line below with the one above
-- set("n", "m", "mzJ`z", { silent = true })

-- -- move the line up/down while selected
set("v", "J", ":m '>+1<CR>gv=gv", { silent = true })
set("v", "K", ":m '<-2<CR>gv=gv", { silent = true })
-- -- move half a screen up/down in normal mode
-- set("n", "J", "<C-d>zz", { silent = true })
-- set("n", "K", "<C-u>zz", { silent = true })

-- -- open diagnostic pane
-- set("n", "<leader>e", vim.diagnostic.setloclist, { silent = true })

-- -- pastig without coping
-- set("x", "<leader>p", [["_dP]], { silent = true })

-- -- change the word under the cursor with or without confirmation
-- set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], { silent = true })
-- set("n", "<leader>S", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gcI<Left><Left><Left><Left>]], { silent = true })

-- -- make the current file executable
-- set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true })

-- -- go  to next or previous error
-- --set("n", "<C-k>", "<cmd>cnext<CR>zz", { silent = true })
-- --set("n", "<C-j>", "<cmd>cprev<CR>zz", { silent = true })

-- --modify the normal go to next highlighted
-- set("n", "n", "nzzzv", { silent = true })
-- set("n", "N", "Nzzzv", { silent = true })

-- -- Panes move and create them
-- set("n", "<C-b>", ":split<CR>", { silent = true })
-- set("n", "<C-n>", ":vsplit<CR>", { silent = true })
-- set("n", "<Down>", ":wincmd j<CR>", { silent = true })
-- set("n", "<Up>", ":wincmd k<CR>", { silent = true })
-- set("n", "<Right>", ":wincmd l<CR>", { silent = true })
-- set("n", "<Left>", ":wincmd h<CR>", { silent = true })

-- set("n", "-", ":resize +2<CR>", { noremap = true, silent = true })
-- set("n", "=", ":resize -2<CR>", { noremap = true, silent = true })
-- set("n", "+", ":vertical resize +2<CR>", { noremap = true, silent = true })
-- set("n", "_", ":vertical resize -2<CR>", { noremap = true, silent = true })

-- -- run tmux scripts inside nvim
-- set("n", "<Esc>g", "<cmd>!~/.config/tmux/tmux-dp1.sh<CR><CR>", { silent = true })
-- set("n", "<Esc>f", "<cmd>!~/.config/tmux/tmux-recursive.sh<CR><CR>", { silent = true })