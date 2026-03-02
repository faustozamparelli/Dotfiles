vim.o.shell = "/opt/homebrew/bin/fish"

vim.g.mapleader = " "
vim.opt.clipboard = "unnamedplus"
vim.opt.mouse = ""
vim.o.cmdheight = 4
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.splitright = true
vim.opt.cursorline = true
vim.o.hlsearch = true
vim.o.incsearch = true

vim.wo.foldlevel = 99
vim.wo.foldmethod = "expr"
vim.wo.foldexpr = "nvim_treesitter#foldexpr()"

local set = vim.keymap.set

set("n", "L", "$", { silent = true })
set("n", "H", "^", { silent = true })
set("v", "J", ":m '>+1<CR>gv=gv", { silent = true })
set("v", "K", ":m '<-2<CR>gv=gv", { silent = true })

vim.keymap.set("n", "<leader><leader>", function()
  vim.fn.VSCodeNotify("workbench.action.files.save")
end, { silent = true })

vim.opt.shortmess:append("I")  -- no intro message
vim.opt.shortmess:append("s")  -- suppress "search hit BOTTOM" etc
vim.opt.shortmess:append("c")  -- suppress completion messages
vim.opt.shortmess:append("A")  -- suppress "ATTENTION" messages
vim.opt.shortmess:append("W")  -- suppress "written" messages
vim.opt.shortmess:append("F")  -- suppress file info messages
vim.opt.shortmess:append("O")  -- suppress line count messages like "5 more lines"
