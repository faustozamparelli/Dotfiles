return {
	"nvim-telescope/telescope.nvim",
	branch = "0.1.x",
	dependencies = { "nvim-lua/plenary.nvim", "nvim-telescope/telescope-ui-select.nvim" },
	config = function()
		local builtin = require("telescope.builtin")
		vim.keymap.set("n", "<C-f>", builtin.find_files, {})
		vim.keymap.set("n", "<C-d>", builtin.live_grep, {})
		vim.api.nvim_set_keymap(
			"n",
			"<C-M-d>",
			"<cmd>lua require('telescope.builtin').grep_string({ search = vim.fn.expand('<cword>') })<CR>",
			{ noremap = true, silent = true }
		)
		vim.keymap.set("n", "<C-e>", builtin.buffers, {})
		vim.keymap.set("n", "H", ":bprev<CR>", { silent = true })
		vim.keymap.set("n", "L", ":bnext<CR>", { silent = true })
		vim.keymap.set("n", "<leader>ht", builtin.help_tags, {})

		require("telescope").setup({
			defaults = {
				mappings = {
					i = {
						["<C-b>"] = require("telescope.actions").select_horizontal,
						["<C-n>"] = require("telescope.actions").select_vertical,
						["<C-x>"] = require("telescope.actions").delete_buffer,
					},
				},
			},
			extensions = {
				["ui-select"] = {
					require("telescope.themes").get_dropdown({}),
				},
			},
		})
		require("telescope").load_extension("ui-select")
	end,
}
