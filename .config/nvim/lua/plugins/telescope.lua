return {
	"nvim-telescope/telescope.nvim",
	branch = "0.1.x",
	cmd = "Telescope",
    keys = {
		{ "<C-f>", "<cmd>Telescope find_files<cr>", desc = "Find files" },
    {
      "<C-g>",
      function()
        require("telescope.builtin").live_grep({
          additional_args = function()
            return { "--case-sensitive" }
          end,
        })
      end,
      desc = "Live grep (case sensitive)",
    },
		{ "<C-G>", "<cmd>Telescope grep_string<cr>", desc = "Grep string" },
		{ "<C-e>", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
		{ "<leader>ht", "<cmd>Telescope help_tags<cr>", desc = "Help tags" },
		{ "H", ":bprev<CR>", desc = "Previous buffer" },
		{ "L", ":bnext<CR>", desc = "Next buffer" },
	},
	dependencies = { 
		"nvim-lua/plenary.nvim", 
		{ "nvim-telescope/telescope-ui-select.nvim", lazy = true }
	},
	config = function()
		-- No need to set keymaps here since they're defined in keys

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
