return {
	"shortcuts/no-neck-pain.nvim",
	version = "*",
	config = function()
		vim.keymap.set("n", "<leader>ct", "<cmd>:NoNeckPain<CR>")
		vim.keymap.set("n", "0", "<cmd>:NoNeckPainWidthUp<CR>")
		vim.keymap.set("n", "9", "<cmd>:NoNeckPainWidthDown<CR>")
		require("no-neck-pain").setup({
			buffers = {
				scratchPad = {
					enabled = true,
					location = "~/.config/nvim/notes/",
				},
				bo = {
					filetype = "md",
				},
			},
		})
	end,
}
