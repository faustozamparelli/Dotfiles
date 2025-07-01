local set = vim.keymap.set

-- dismiss copilot suggestions
-- set("i", "<C-c>", "<plug>(copilot-dismiss)<C-c>", { silent = true })

-- removes the highlight
set("n", "<C-c>", "<cmd>nohlsearch<CR>", { silent = true })

-- end/start of line
set("n", "J", "$", { silent = true, noremap = true })
set("n", "K", "^", { silent = true, noremap = true })

-- jump between parentheses
set("n", "[", "%", { silent = true })

--save the file
--set("n", "<leader><leader>", ":w<CR>:lua vim.lsp.buf.format()<CR>", { silent = true })
set("n", "<leader><leader>", ":w<CR>", { silent = true })

-- previous/next diagnostic
set("n", "[d", vim.diagnostic.goto_prev, { silent = true })
set("n", "]d", vim.diagnostic.goto_next, { silent = true })

--open terminal and get out of insert mode
set("n", "<C-t>", ":term<CR>i", { silent = true })
set("t", "<Esc>", "<C-\\><C-n>", { silent = true })

-- quit the file and close tmux window
set("n", "<C-w>", "<cmd>:w<CR>:silent !tmux kill-window<CR>", { silent = true })

-- close the current buffer
set("n", "<S-q>", "<cmd>:w<CR>:bd<CR>", { silent = true })

-- reload the file
set("n", "<S-w>", ":w | so<CR>", { silent = true })

-- join the line below with the one above
set("n", "m", "mzJ`z", { silent = true })

-- move the line up/down while selected
set("v", "J", ":m '>+1<CR>gv=gv", { silent = true })
set("v", "K", ":m '<-2<CR>gv=gv", { silent = true })
-- move half a screen up/down in normal mode
set("n", "J", "<C-d>zz", { silent = true })
set("n", "K", "<C-u>zz", { silent = true })

-- open diagnostic pane
set("n", "<leader>e", vim.diagnostic.setloclist, { silent = true })

-- pastig without coping
set("x", "<leader>p", [["_dP]], { silent = true })

-- change the word under the cursor with or without confirmation
set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], { silent = true })
set("n", "<leader>S", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gcI<Left><Left><Left><Left>]], { silent = true })

-- make the current file executable
set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true })

-- go  to next or previous error
--set("n", "<C-k>", "<cmd>cnext<CR>zz", { silent = true })
--set("n", "<C-j>", "<cmd>cprev<CR>zz", { silent = true })

--modify the normal go to next highlighted
set("n", "n", "nzzzv", { silent = true })
set("n", "N", "Nzzzv", { silent = true })

-- Panes move and create them
set("n", "<C-b>", ":split<CR>", { silent = true })
set("n", "<C-n>", ":vsplit<CR>", { silent = true })
set("n", "<Down>", ":wincmd j<CR>", { silent = true })
set("n", "<Up>", ":wincmd k<CR>", { silent = true })
set("n", "<Right>", ":wincmd l<CR>", { silent = true })
set("n", "<Left>", ":wincmd h<CR>", { silent = true })

set("n", "-", ":resize +2<CR>", { noremap = true, silent = true })
set("n", "=", ":resize -2<CR>", { noremap = true, silent = true })
set("n", "+", ":vertical resize +2<CR>", { noremap = true, silent = true })
set("n", "_", ":vertical resize -2<CR>", { noremap = true, silent = true })

-- run tmux scripts inside nvim
set("n", "<Esc>g", "<cmd>!~/.config/tmux/tmux-dp1.sh<CR><CR>", { silent = true })
set("n", "<Esc>f", "<cmd>!~/.config/tmux/tmux-recursive.sh<CR><CR>", { silent = true })

-- vim.api.nvim_set_keymap(
-- 	"n",
-- 	"<C-e>",
-- 	[[:lua YankDiagnosticError()<CR>]],
-- 	{ noremap = true, silent = true, desc = "Copy error" }
-- )

-- function YankDiagnosticError()
-- 	vim.diagnostic.open_float()
-- 	vim.diagnostic.open_float()
-- 	local win_id = vim.fn.win_getid() -- get the window ID of the floating window
-- 	vim.cmd("normal! j") -- move down one row
-- 	vim.cmd("normal! VG") -- select everything from that row down
-- 	vim.cmd("normal! y") -- yank selected text
-- 	vim.api.nvim_win_close(win_id, true) -- close the floating window by its ID
-- end

vim.api.nvim_create_user_command("Cd", function(opts)
	local path = opts.args
	if path == "" then
		path = vim.fn.expand("~")
	end

	-- Change vim's working directory
	vim.cmd("cd " .. vim.fn.fnameescape(path))

	-- If oil is available, also open it there
	local ok, oil = pcall(require, "oil")
	if ok then
		oil.open(path)
	end
end, {
	nargs = "?",
	complete = "dir",
	desc = "Change directory and open in oil",
})

-- -- open diagnostics
-- set("n", "<S-e>", vim.diagnostic.open_float, { silent = true })
-- -- move to the next location list
-- set("n", "K", "<cmd>lnext<CR>zz", { silent = true })
-- set("n", "J", "<cmd>lprev<CR>zz", { silent = true })

-- Startup profiling command
vim.api.nvim_create_user_command("StartupTime", function()
	vim.cmd("!time nvim +qall")
end, { desc = "Measure startup time" })
