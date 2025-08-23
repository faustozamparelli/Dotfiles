--SETTINGS
vim.o.number = true               -- Show absolute line numbers on the left
vim.o.relativenumber = true       -- Show relative line numbers (distance from current line)
vim.opt.signcolumn = "yes"        -- Always show the sign column (for git signs, diagnostics, etc.)
vim.opt.clipboard = "unnamedplus" --use the system clipboard

vim.o.wrap = true                 -- Enable line wrapping for long lines
vim.o.tabstop = 2                 -- Set tab width to 2 spaces
vim.opt.shiftwidth = 2            -- Set indentation width to 2 spaces (for << and >> commands)
vim.opt.smartindent = true        -- Enable smart auto-indenting for new lines

vim.g.mapleader = " "             -- Set space as the leader key for custom keybindings
vim.cmd([[set mouse=]])           -- Disable mouse support completely

vim.opt.winborder = "rounded"     -- Use rounded borders for floating windows
vim.opt.termguicolors = true      -- Enable 24-bit RGB color support in terminal
vim.opt.hlsearch = true           -- Keep search highlights after searching
vim.opt.incsearch = true          -- Incremental search while typing
vim.opt.cursorcolumn = false      -- Don't highlight the current column
vim.opt.ignorecase = true         -- Ignore case when searching
vim.opt.undofile = true           -- Enable persistent undo (undo history survives restarts)

--------------------------------------------------------------------
--KEYBINDINGS
local map = vim.keymap.set    -- Shorthand for creating keymaps
vim.g.mapleader = " "         -- Set leader key again (redundant but explicit)
map("n", "<C-c>", ":noh<CR>") --remove highlight


-- File operations
map('n', '<leader>o', ':update<CR> :source<CR> :noh<CR>') -- Save file and reload config
map('n', '<leader>w', ':write<CR>')              -- Save current file
map('n', '<leader>q', ':quit<CR>')               -- Quit current window

-- Quick config access
map('n', '<leader>v', ':e $MYVIMRC<CR>')             -- Open Neovim config file
map('n', '<leader>z', ':e ~/.config/zsh/.zshrc<CR>') -- Open Zsh config file

-- Buffer navigation
map('n', '<leader>s', ':e #<CR>')  -- Switch to alternate buffer
map('n', '<leader>S', ':sf #<CR>') -- Split window with alternate buffer

-- Spell check
map({ 'n', 'v' }, '<leader>c', '1z=') -- Use first spelling suggestion

-- File picker and help
map('n', '<leader>f', ":Pick files<CR>") -- Open file picker
map('n', '<leader>h', ":Pick help<CR>")  -- Open help picker

-- File manager
map('n', ';', ":Oil<CR>") -- Open Oil file manager

-- LSP formatting
map('n', '<leader>lf', vim.lsp.buf.format) -- Format current buffer using LSP

-- End and Start of Line
map("n", "H", "^")
map("n", "L", "$")


---------------------------------------------------------------------
--PLUGINS
vim.pack.add({
	-- Color scheme - high contrast dark theme
	{ src = "https://github.com/iagorrr/noctis-high-contrast.nvim" },

	-- Alternative theme (commented out)
	--{src = "https://github.com/vague2k/vague.nvim"}, --theme2

	-- File manager plugin - browse and edit directories
	{ src = "https://github.com/stevearc/oil.nvim" },

	-- Fuzzy finder for files, buffers, help, etc.
	{ src = "https://github.com/echasnovski/mini.pick" },

	-- Syntax highlighting and text objects
	{ src = "https://github.com/nvim-treesitter/nvim-treesitter",  version = "main" },

	-- Live preview for Typst documents
	{ src = "https://github.com/chomosuke/typst-preview.nvim" },

	-- LSP configuration helper
	{ src = 'https://github.com/neovim/nvim-lspconfig' },

	-- LSP server installer and manager
	{ src = "https://github.com/mason-org/mason.nvim" },

	-- Show pressed keys on screen (loaded optionally)
	{ src = 'https://github.com/NvChad/showkeys',                  opt = true },

	-- Snippet engine for code completion
	{ src = "https://github.com/L3MON4D3/LuaSnip" },

	-- Commenting
	{ src = "https://github.com/numToStr/Comment.nvim" }
})

--------------------------------------------------------------------
--THEME
vim.cmd("colorscheme noctishc") -- Apply the noctis high contrast color scheme

-- Alternative theme setup (commented out)
--require "vague".setup({ transparent = true })
--vim.cmd("colorscheme vague")
--vim.cmd(":hi statusline guibg=NONE")

--------------------------------------------------------------------
-- PLUGIN SETUP

-- Setup Mason for LSP server management
require "mason".setup()

-- Setup showkeys to display pressed keys in top-right corner
require "showkeys".setup({ position = "top-right" })

-- Setup mini.pick fuzzy finder
require "mini.pick".setup({ mappings = { choose_in_vsplit = '<CR>', } })

-- Setup Oil file manager
require "oil".setup()

-- Enable LSP servers for various languages
vim.lsp.enable({ "lua_ls", "clangd" })

-- SNIPPETS CONFIGURATION
-- Setup LuaSnip with auto-expanding snippets
require("luasnip").setup({ enable_autosnippets = true })

-- Load custom snippets from config directory
require("luasnip.loaders.from_lua").load({ paths = "~/.config/nvim/snippets/" })

-- Comment.nvim setup
require("Comment").setup()

-- cm to comment
map("n", "cm", "<cmd>lua require('Comment.api').toggle.linewise.current()<CR>")
map("v", "cm", "<esc><cmd>lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<CR>")

-- Create local reference to LuaSnip
local ls = require("luasnip")

-- Snippet navigation keybindings
map("i", "<C-e>", function() ls.expand_or_jump(1) end, { silent = true }) -- Expand snippet or jump forward
map({ "i", "s" }, "<C-J>", function() ls.jump(1) end, { silent = true })  -- Jump to next snippet placeholder
map({ "i", "s" }, "<C-K>", function() ls.jump(-1) end, { silent = true }) -- Jump to previous snippet placeholder
