return {
	{ "github/copilot.vim", config = function() end },
	{
		"iagorrr/noctishc.nvim",
		config = function()
			vim.cmd([[set termguicolors]])
			vim.cmd([[syntax enable]])
			vim.cmd([[colorscheme noctishc]])
		end,
	},

	{
		"stevearc/oil.nvim",
		config = function()
			require("oil").setup({
				default_file_explorer = true,
				columns = {
					"size",
				},
				skip_confirm_for_simple_edits = true,
				cleanup_delay_ms = 1000,
				use_default_keymaps = false,
				keymaps = {
					["<CR>"] = "actions.select",
					["<C-c>"] = "actions.close",
					["s"] = "actions.change_sort",
				},
			})
			vim.keymap.set("n", "'", "<CMD>Oil<CR>", { desc = "Open parent directory" })
		end,
	},
}
