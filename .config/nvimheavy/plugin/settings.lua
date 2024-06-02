vim.o.shell = "/opt/homebrew/bin/fish"
--vim.cmd([[autocmd VimEnter,VimLeave * silent !tmux set status]])
vim.env.NVIM_LISTEN_ADDRESS = vim.v.servername
vim.g.mapleader = " "
vim.keymap.set("n", "U", "<C-r>")
vim.opt.relativenumber = true
vim.opt.mouse = ""
vim.opt.showmode = false
vim.opt.wrap = false
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.clipboard = "unnamedplus"
vim.opt.undodir = "/Users/faustozamparelli/.config/nvim/undodir/"
vim.opt.undofile = true
vim.opt.breakindent = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.updatetime = 2000
vim.opt.timeoutlen = 300
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.inccommand = "split"
vim.opt.scrolloff = 15
vim.opt.cursorline = true
vim.opt.signcolumn = "yes"
vim.o.hlsearch = true
vim.o.incsearch = true
vim.opt.backup = false
vim.opt.swapfile = false
vim.opt.writebackup = false
vim.opt.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
vim.cmd([[set laststatus=3]])
vim.api.nvim_create_autocmd("TermOpen", {
	pattern = "*",
	callback = function()
		vim.opt_local.relativenumber = false
		vim.opt_local.signcolumn = "no"
	end,
})
vim.cmd([[cnoremap <Down> <C-n>]])
vim.cmd([[cnoremap <Up> <C-p>]])

vim.cmd([[autocmd BufRead,BufWrite ~/.config/nvim/notes/* set nobuflisted bufhidden=wipe]])
vim.cmd([[ autocmd VimEnter * if argc() == 0 | call luaeval('require("nvim-possession").list()') | endif ]])

--vim.cmd([[highlight WinSeparator guibg=None]])
--vim.wo.conceallevel = 0

-- vim.cmd([[
-- autocmd VimEnter * if argc() == 0 | call luaeval('require("nvim-possession").list()') | endif
-- ]])
