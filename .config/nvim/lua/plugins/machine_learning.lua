return {
	{
		"GCBallesteros/jupytext.nvim",
		config = true,
		-- Depending on your nvim distro or config you may need to make the loading not lazy
		-- lazy=false,
	},
	{
		"jpalardy/vim-slime",
		init = function()
			vim.g.slime_last_channel = { nil }
			-- will use `# %%` to define cells
			vim.g.slime_cell_delimiter = "\\s*#\\s*%%"
			vim.g.slime_paste_file = os.getenv("HOME") .. "/.slime_paste"

			local function next_cell()
				vim.fn.search(vim.g.slime_cell_delimiter)
			end

			local function prev_cell()
				vim.fn.search(vim.g.slime_cell_delimiter, "b")
			end

			vim.keymap.set("n", "<leader>e", vim.cmd.SlimeSend, { noremap = true, desc = "send line to term" })
			-- vim.keymap.set(
			-- 	"n",
			-- 	"<leader>cv",
			-- 	vim.cmd.SlimeConfig,
			-- 	{ noremap = true, desc = "Open slime configuration" }
			-- )
			vim.api.nvim_set_keymap("n", "<leader>cn", "o# %%<Esc>o", { noremap = true, silent = true })
			vim.keymap.set("x", "<leader>e", "<Plug>SlimeRegionSend", { noremap = true, desc = "send line to tmux" })
			vim.keymap.set(
				"n",
				"<leader>ep",
				"<Plug>SlimeParagraphSend",
				{ noremap = true, desc = "Send Paragraph with Slime" }
			)
			vim.keymap.set(
				"n",
				"<leader>ck",
				prev_cell,
				{ noremap = true, desc = "Search backward for slime cell delimiter" }
			)
			vim.keymap.set(
				"n",
				"<leader>cj",
				next_cell,
				{ noremap = true, desc = "Search forward for slime cell delimiter" }
			)
			vim.keymap.set("n", "<leader>cc", "<Plug>SlimeSendCell", { noremap = true, desc = "Send cell to slime" })

			local slime_get_jobid = function()
				local buffers = vim.api.nvim_list_bufs()
				local terminal_buffers = { "Select terminal:\tjobid\tname" }
				local name = ""
				local jid = 1
				local chosen_terminal = 1

				for _, buf in ipairs(buffers) do
					if vim.bo[buf].buftype == "terminal" then
						jid = vim.api.nvim_buf_get_var(buf, "terminal_job_id")
						name = vim.api.nvim_buf_get_name(buf)
						table.insert(terminal_buffers, jid .. "\t" .. name)
					end
				end

				-- if there is more than one terminal, ask which one to use
				if #terminal_buffers > 2 then
					chosen_terminal = vim.fn.inputlist(terminal_buffers)
				else
					chosen_terminal = jid
				end

				if chosen_terminal then
					print("\n[slime] jobid chosen: ", chosen_terminal)
					return chosen_terminal
				else
					print("No terminal found")
				end
			end

			local function slime_use_tmux()
				vim.g.slime_target = "tmux"
				vim.g.slime_bracketed_paste = 1
				vim.g.slime_python_ipython = 0
				vim.g.slime_no_mappings = 1
				vim.g.slime_default_config = { socket_name = "default", target_pane = ":.1" }
				vim.g.slime_dont_ask_default = 1
			end

			local function slime_use_neovim()
				vim.g.slime_target = "neovim"
				vim.g.slime_bracketed_paste = 1
				vim.g.slime_python_ipython = 1
				vim.g.slime_no_mappings = 1
				vim.g.slime_get_jobid = slime_get_jobid
				-- vim.g.slime_default_config = nil
				-- vim.g.slime_dont_ask_default = 0
			end

			--slime_use_neovim()
			slime_use_tmux()
			-- }}
		end,
	},
}
