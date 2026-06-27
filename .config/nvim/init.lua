vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

require('fausto.options')
require('fausto.theme').setup()
require('fausto.plugins')
require('fausto.lsp')
require('fausto.keymaps')
require('fausto.autocmds')
