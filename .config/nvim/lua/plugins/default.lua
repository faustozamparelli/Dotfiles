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
		dependencies = {
			{ "echasnovski/mini.icons", opts = {} },
		},
		config = function()
			require("oil").setup({
				default_file_explorer = true,
				columns = {
          "icon",
					--"size",
          --"permissions",
          --"mtime",
				},
				skip_confirm_for_simple_edits = true,
				cleanup_delay_ms = 1000,
				use_default_keymaps = false,
				keymaps = {
					["<CR>"] = "actions.select",
					["<C-o>"] = "actions.open_external",
					["<C-c>"] = "actions.close",
					["s"] = "actions.change_sort",
					["z"] = {
						desc = "Jump to directory with zoxide",
						callback = function()
							local oil = require("oil")
							vim.ui.input({ prompt = "Zoxide query: " }, function(query)
								if query then
									local handle = io.popen("zoxide query " .. vim.fn.shellescape(query))
									local result = handle:read("*a")
									handle:close()

									result = result:gsub("\n$", "")

									if result and result ~= "" then
										-- Change vim's working directory
										vim.cmd("cd " .. vim.fn.fnameescape(result))
										-- Open the directory in oil
										oil.open(result)
									else
										vim.notify("No directory found for: " .. query)
									end
								end
							end)
						end,
					},
				},
				view_options = {
					show_hidden = true,
				},
			})
			vim.keymap.set("n", "'", "<CMD>Oil<CR>", { desc = "Open parent directory" })
		end,
	},
	{
		"numToStr/Comment.nvim",
		opts = {},
		lazy = false,
		config = function()
			require("Comment").setup({
				toggler = {
					line = "cm",
				},
				opleader = {
					line = "cm",
				},
			})
		end,
	},
	{
		"ggandor/leap.nvim",
		enabled = true,
		keys = {
			{ "s", mode = { "n", "x", "o" }, desc = "Leap Forward to" },
			{ "S", mode = { "n", "x", "o" }, desc = "Leap Backward to" },
			{ "gs", mode = { "n", "x", "o" }, desc = "Leap from Windows" },
		},
		config = function(_, opts)
			local leap = require("leap")
			for k, v in pairs(opts) do
				leap.opts[k] = v
			end
			leap.add_default_mappings(true)
		end,
	},
	{
		"kdheepak/lazygit.nvim",
		cmd = {
			"LazyGit",
			"LazyGitConfig",
			"LazyGitCurrentFile",
			"LazyGitFilter",
			"LazyGitFilterCurrentFile",
		},
		-- optional for floating window border decoration
		dependencies = {
			"nvim-lua/plenary.nvim",
		},
		-- setting the keybinding for LazyGit with 'keys' is recommended in
		-- order to load the plugin when the command is run for the first time
		keys = {
			{ "<leader>lg", "<cmd>LazyGit<cr>", desc = "Open lazy git" },
		},
	},
	{
		"windwp/nvim-autopairs",
		event = "InsertEnter",
		config = function()
			local npairs = require("nvim-autopairs")
			npairs.setup({})
		end,
	},
	{
		"lukas-reineke/indent-blankline.nvim",
		main = "ibl",
		config = function()
			require("ibl").setup({ scope = { show_start = false, show_end = false, show_exact_scope = false } })
		end,
	},
	{
		"iamcco/markdown-preview.nvim",
		cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
		ft = { "markdown" },
		build = function()
			vim.fn["mkdp#util#install"]()
		end,
		config = function()
			vim.keymap.set("n", "<leader>mp", "<CMD>MarkdownPreviewToggle<CR>", { desc = "Markdown Preview" })
		end,
	},
	{
		"thinca/vim-quickrun",
		keys = {
			{ "<leader>r", "<cmd>QuickRun<CR>", desc = "Run QuickRun" },
		},
		config = function()
			vim.g.quickrun_config = {
				cpp = {
					command = "/opt/homebrew/bin/g++-14",
					["hook/time/enable"] = 1,
					["hook/time/precision"] = 3,
				},
				python = {
					command = "python3",
				},
			}
		end,
	},
}
