vim.g.mapleader = " " --leader key space

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim" --lazy.nvim path
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable",
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

-- Defer Python setup to after startup for faster boot
vim.schedule(function()
	local venv_path = os.getenv("VIRTUAL_ENV")
	if venv_path ~= nil then
		vim.g.python3_host_prog = venv_path .. "/bin/python"
		vim.g.pip3_path = venv_path .. "/bin/pip"
	else
		-- Properly close file handles to prevent memory leaks
		local pyenv_python_handle = io.popen("pyenv which python")
		local pyenv_python = pyenv_python_handle:read("*a")
		pyenv_python_handle:close()
		vim.g.python3_host_prog = pyenv_python:sub(1, -2)
		
		local pyenv_pip_handle = io.popen("pyenv which pip")
		local pyenv_pip = pyenv_pip_handle:read("*a")
		pyenv_pip_handle:close()
		vim.g.pip3_path = pyenv_pip:sub(1, -2)
	end
end)

require("lazy").setup("plugins", {
	defaults = { lazy = true }, -- Make all plugins lazy by default
	performance = {
		cache = { enabled = true },
		reset_packpath = true,
		rtp = {
			reset = true,
			paths = {},
			disabled_plugins = {
				"gzip", "matchit", "matchparen", "netrwPlugin", "tarPlugin", 
				"tohtml", "tutor", "zipPlugin", "rplugin", "synmenu", "optwin"
			},
		},
	},
	install = { missing = false }, -- Don't auto-install missing plugins
})
require("settings.remap")
require("settings.settings")
