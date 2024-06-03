vim.g.mapleader = " "

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
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

local venv_path = os.getenv("VIRTUAL_ENV")

if venv_path ~= nil then
	vim.g.python3_host_prog = venv_path .. "/bin/python"
	vim.g.pip3_path = venv_path .. "/bin/pip"
else
	local pyenv_python = io.popen("pyenv which python"):read("*a")
	vim.g.python3_host_prog = pyenv_python:sub(1, -2)
	local pyenv_pip = io.popen("pyenv which pip"):read("*a")
	vim.g.pip3_path = pyenv_pip:sub(1, -2)
end

require("lazy").setup("plugins")
require("settings.remap")
require("settings.settings")
