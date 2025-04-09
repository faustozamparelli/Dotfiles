return {
	-- Mason: LSP server, Linter, and Formatter manager
	{
		"williamboman/mason.nvim",
		config = function()
			require("mason").setup()
		end,
	},
	-- Use mason-tool-installer.nvim to ensure external tools are installed
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		config = function()
			require("mason-tool-installer").setup({
				ensure_installed = {
					"prettierd", -- JS/TS/HTML/CSS formatter
					"black", -- Python formatter
					"shfmt", -- Bash/Zsh formatter
					"gofumpt", -- Go formatter
					"eslint_d", -- JS/TS linter
					"stylua", -- Lua formatter
				},
				auto_update = false,
				run_on_start = true,
			})
		end,
	},
	-- Mason LSP Config
	{
		"williamboman/mason-lspconfig.nvim",
		dependencies = { "williamboman/mason.nvim" },
		config = function()
			require("mason-lspconfig").setup({
				ensure_installed = {
					"pyright", -- Python
					"ts_ls", -- TypeScript and JavaScript (Fixed name)
					"gopls", -- Go
					"clangd", -- C, C++
					"html", -- HTML
					"cssls", -- CSS
					"bashls", -- Bash/Zsh LSP
					"svelte", -- Svelte language server
				},
			})
		end,
	},
	-- LSP Configuration
	{
		"neovim/nvim-lspconfig",
		dependencies = { "williamboman/mason-lspconfig.nvim" },
		config = function()
			local lspconfig = require("lspconfig")
			local capabilities = require("cmp_nvim_lsp").default_capabilities()

			local on_attach = function(_, bufnr)
				local bufopts = { noremap = true, silent = true, buffer = bufnr }
				local builtin = require("telescope.builtin") -- Use Telescope for references

				vim.keymap.set("n", "gd", vim.lsp.buf.definition, bufopts)
				vim.keymap.set("n", "gr", builtin.lsp_references, bufopts)
				vim.keymap.set("n", "gD", vim.lsp.buf.declaration, bufopts)
				vim.keymap.set("n", "gT", vim.lsp.buf.type_definition, bufopts)
				vim.keymap.set("n", "K", vim.lsp.buf.hover, bufopts)
				vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, bufopts)
				vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, bufopts)
				vim.keymap.set("n", "<leader>f", function()
					vim.lsp.buf.format({ async = true })
				end, bufopts)
				-- Auto-format on save
				vim.api.nvim_create_autocmd("BufWritePre", {
					buffer = bufnr,
					callback = function()
						vim.lsp.buf.format({ async = false })
					end,
				})
			end

			-- Setup each server
			local servers = { "pyright", "ts_ls", "gopls", "clangd", "html", "cssls", "bashls", "svelte" }
			for _, server in ipairs(servers) do
				lspconfig[server].setup({
					capabilities = capabilities,
					on_attach = on_attach,
				})
			end
		end,
	},
	-- Auto-completion
	{
		"hrsh7th/nvim-cmp",
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
			"saadparwaiz1/cmp_luasnip",
		},
		config = function()
			local cmp = require("cmp")
			cmp.setup({
				snippet = {
					expand = function(args)
						require("luasnip").lsp_expand(args.body)
					end,
				},
				mapping = {
					["<S-Tab>"] = cmp.mapping.select_prev_item(),
					["<Tab>"] = cmp.mapping.select_next_item(),
					["<C-Space>"] = cmp.mapping.complete(),
					["<C-y>"] = cmp.mapping.confirm({ select = true }),
				},
				sources = {
					{ name = "nvim_lsp" },
					{ name = "buffer" },
					{ name = "path" },
				},
			})
		end,
	},
	-- Conform for linting and formatting
	{
		"stevearc/conform.nvim",
		config = function()
			require("conform").setup({
				-- Specify which external formatters to use for each filetype.
				-- Each formatter should already be installed via Mason or a similar tool.
				formatters_by_ft = {
					lua = { "stylua" },
					python = { "black" },
					javascript = { "prettierd" },
					typescript = { "prettierd" },
					html = { "prettierd" },
					css = { "prettierd" },
					go = { "gofumpt" },
					sh = { "shfmt" },
					svelte = { "prettierd" },
				},
				-- Enable format on save; you can customize the timeout (in milliseconds).
				format_on_save = {
					timeout = 500,
				},
			})

			-- Optionally, set up a key mapping for manual formatting:
			vim.keymap.set("n", "<leader>f", function()
				require("conform").format({ async = true })
			end, { desc = "Format file with conform.nvim" })
		end,
	},
	-- Snippets
	{
		"L3MON4D3/LuaSnip",
		config = function()
			require("luasnip.loaders.from_vscode").lazy_load()
		end,
	},
	-- Svelte Syntax Highlighting Plugin
	{
		"evanleck/vim-svelte",
		ft = "svelte", -- load only for Svelte files
		config = function()
			-- The plugin usually sets the correct filetype automatically,
			-- but you can add extra configuration if needed.
		end,
	},
	-- Optional: Ensure the filetype is set to svelte explicitly (if needed)
	{
		"folke/neodev.nvim", -- Or place these lines in your init.lua/init.vim if you prefer not to add another plugin for this
		config = function()
			vim.cmd([[
				augroup svelte_ft
					autocmd!
					autocmd BufRead,BufNewFile *.svelte set filetype=svelte
				augroup END
			]])
		end,
	},
}
