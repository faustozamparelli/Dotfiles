return {
	"shortcuts/no-neck-pain.nvim",
	version = "*",
	config = function()
		vim.keymap.set("n", "<leader>f", "<cmd>:NoNeckPain<CR>")
		vim.keymap.set("n", "<C-]>", "<cmd>:NoNeckPainWidthUp<CR>")
		vim.keymap.set("n", "<C-[>", "<cmd>:NoNeckPainWidthDown<CR>")
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
