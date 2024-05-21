return {
	"gennaro-tedesco/nvim-possession",
	dependencies = {
		"ibhagwan/fzf-lua",
	},
	config = function()
		local possession = require("nvim-possession")
		possession.setup({
			sessions = {
				sessions_path = vim.fn.expand("~/.config/nvim/sessions/"),
			},
			autosave = true,
		})
		vim.keymap.set("n", "<C-d>", function()
			possession.list()
		end)
		vim.keymap.set("n", "<leader>ss", function()
			possession.new()
		end, { desc = "Save session" })
		vim.keymap.set("n", "<leader>su", function()
			possession.update()
		end, { desc = "Update session" })
		vim.keymap.set("n", "<leader>sd", function()
			possession.delete()
		end, { desc = "Delete session" })
		require("fzf-lua").setup({
			files = {
				header = false,
			},
		})
	end,
}
