return {
	{
		"tpope/vim-fugitive",
		config = function()
			vim.keymap.set("n", "<leader>gs", ":Git<CR>", { silent = true })
			vim.keymap.set("n", "<leader>gp", ":Git push<CR>", { silent = true })
			vim.keymap.set("n", "<leader>gl", ":Git pull<CR>", { silent = true })
		end,
	},
	{
		"lewis6991/gitsigns.nvim",
		config = function()
			require("gitsigns").setup()
			vim.keymap.set("n", "<leader>gh", ":Gitsigns preview_hunk<CR>", { silent = true })
		end,
	},
}
