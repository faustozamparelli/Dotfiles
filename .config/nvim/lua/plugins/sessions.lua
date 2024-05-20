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
		vim.keymap.set("n", "<leader>sn", function()
			possession.new()
		end)
		vim.keymap.set("n", "<leader>su", function()
			possession.update()
		end)
		vim.keymap.set("n", "<leader>sd", function()
			possession.delete()
		end)
	end,
}
