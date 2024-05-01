return {
	"tpope/vim-fugitive",
	config = function()
		vim.api.nvim_set_keymap("n", "<C-g>", ":Git<CR>", { noremap = true, silent = true })
		vim.api.nvim_set_keymap("n", "<leader>gl", ":Gclog<CR>", { noremap = true, silent = true })
	end,
}
