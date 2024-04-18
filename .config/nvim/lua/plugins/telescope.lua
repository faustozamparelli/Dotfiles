return {
	'nvim-telescope/telescope.nvim', 
	branch = '0.1.x',
	dependencies = { 'nvim-lua/plenary.nvim' },
	config = function()	
	local builtin = require('telescope.builtin')
		vim.keymap.set('n', '<leader>jf', builtin.find_files, {})
		vim.keymap.set('n', '<C-g>', builtin.git_files, {})
		vim.keymap.set('n', '<leader>js', function()
			builtin.grep_string({ search = vim.fn.input("Grep > ")});
		end)
	end,
}

