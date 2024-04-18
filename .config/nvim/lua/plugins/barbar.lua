return {
	"romgrk/barbar.nvim",
	dependencies = {
		"lewis6991/gitsigns.nvim", -- OPTIONAL: for git status
		"nvim-tree/nvim-web-devicons", -- OPTIONAL: for file icons
	},
	config = function()
		vim.g.barbar_auto_setup = false 
		local map = vim.api.nvim_set_keymap
		local opts = { noremap = true, silent = true }
    require("gitsigns").setup()
    require("nvim-web-devicons").setup()
		-- Move to previous/next
		map("n", "<S-Tab>", "<Cmd>BufferPrevious<CR>", opts)
    map("n", "<Tab>", "<Cmd>BufferNext<CR>", opts)
		-- Re-order to previous/next
		map("n", "<A-<>", "<Cmd>BufferMovePrevious<CR>", opts)
		map("n", "<A->>", "<Cmd>BufferMoveNext<CR>", opts)
		-- Goto buffer in position...
		map("n", "b1", "<Cmd>BufferGoto 1<CR>", opts)
		map("n", "b2", "<Cmd>BufferGoto 2<CR>", opts)
		map("n", "b3", "<Cmd>BufferGoto 3<CR>", opts)
		map("n", "b4", "<Cmd>BufferGoto 4<CR>", opts)
		map("n", "b5", "<Cmd>BufferGoto 5<CR>", opts)
		map("n", "b6", "<Cmd>BufferGoto 6<CR>", opts)
		map("n", "b7", "<Cmd>BufferGoto 7<CR>", opts)
		-- Pin/unpin buffer
		map("n", "<leader>bpi", "<Cmd>BufferPin<CR>", opts)
		-- Close buffer
		map("n", "<leader>q", "<Cmd>BufferClose<CR>", opts)
		map("n", "<leader>bb", "<Cmd>BufferOrderByBufferNumber<CR>", opts)
		map("n", "<leader>bd", "<Cmd>BufferOrderByDirectory<CR>", opts)
		map("n", "<leader>bl", "<Cmd>BufferOrderByLanguage<CR>", opts)
		map("n", "<leader>bw", "<Cmd>BufferOrderByWindowNumber<CR>", opts)
		-- Other:
		-- :BarbarEnable - enables barbar (enabled by default)
		-- :BarbarDisable - very bad command, should never be used
	end,
}
