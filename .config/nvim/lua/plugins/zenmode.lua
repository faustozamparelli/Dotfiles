return {
	"folke/zen-mode.nvim",
	config = function()
		vim.api.nvim_set_keymap("n", "<leader>k", ":ZenMode<CR>", {})
	end,
}
