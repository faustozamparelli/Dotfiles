return {
	{
		"mhinz/vim-startify",
		event = "VimEnter",
		config = function()
			vim.g.startify_session_dir = vim.fn.expand("~/.config/nvim/sessions/")
			vim.g.startify_session_autoload = 1
			vim.g.startify_session_delete_buffers = 1
			vim.g.startify_custom_header = ""
		end,
	},
	{
		"folke/persistence.nvim",
		event = "BufReadPre",
		config = function()
			require("persistence").setup({
				dir = vim.fn.expand("~/.config/nvim/sessions/"),
				options = { "buffers", "curdir", "tabpages", "winsize" },
			})
		end,
	},
}
