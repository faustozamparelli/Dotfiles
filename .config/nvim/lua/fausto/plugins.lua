local gh = function(repo)
    return 'https://github.com/' .. repo
end

vim.pack.add({
    { src = gh('stevearc/oil.nvim') },
    { src = gh('ibhagwan/fzf-lua') },
    { src = gh('neovim-treesitter/treesitter-parser-registry'), version = 'main' },
    { src = gh('neovim-treesitter/nvim-treesitter'), version = 'main' },
    { src = gh('lewis6991/gitsigns.nvim') },
    { src = gh('folke/which-key.nvim') },
    { src = gh('MeanderingProgrammer/render-markdown.nvim') },
}, { confirm = false, load = true })

require('oil').setup({
    default_file_explorer = true,
    delete_to_trash = true,
    skip_confirm_for_simple_edits = false,
    view_options = { show_hidden = true },
})

require('fzf-lua').setup({
    winopts = { height = 0.85, width = 0.85, preview = { layout = 'vertical' } },
    files = { git_icons = false },
})

local treesitter_languages = {
    'bash',
    'c',
    'cpp',
    'fish',
    'json',
    'lua',
    'markdown',
    'markdown_inline',
    'python',
    'toml',
    'tsv',
    'vim',
    'vimdoc',
    'yaml',
}

require('nvim-treesitter').install(treesitter_languages)
vim.treesitter.language.register('bash', 'sh')

vim.api.nvim_create_autocmd('FileType', {
    desc = 'Enable Tree-sitter highlighting and indentation',
    pattern = {
        'bash',
        'sh',
        'c',
        'cpp',
        'fish',
        'json',
        'lua',
        'markdown',
        'markdown_inline',
        'python',
        'toml',
        'tsv',
        'vim',
        'vimdoc',
        'help',
        'checkhealth',
        'yaml',
    },
    callback = function(args)
        vim.treesitter.start(args.buf)
        vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end,
})

require('gitsigns').setup({ current_line_blame = false })

require('render-markdown').setup({
    enabled = true,
    heading = {
        sign = false,
        icons = { '━━ ', '━ ', '◆ ', '◇ ', '▸ ', '· ' },
        position = 'inline',
        width = 'block',
        backgrounds = { 'Normal' },
        foregrounds = {
            'RenderMarkdownH1',
            'RenderMarkdownH2',
            'RenderMarkdownH3',
            'RenderMarkdownH4',
            'RenderMarkdownH5',
            'RenderMarkdownH6',
        },
    },
    code = {
        style = 'normal',
        width = 'block',
        border = 'thin',
        highlight = 'RenderMarkdownCode',
        highlight_border = 'RenderMarkdownCodeBorder',
        highlight_inline = 'RenderMarkdownCodeInline',
    },
    bullet = {
        icons = { '•' },
        highlight = 'RenderMarkdownMuted',
    },
    checkbox = {
        unchecked = {
            icon = '[ ] ',
            highlight = 'RenderMarkdownMuted',
        },
        checked = {
            icon = '[x] ',
            highlight = 'RenderMarkdownChecked',
        },
    },
})

require('which-key').setup({ preset = 'helix', delay = 250 })
require('which-key').add({
    { '<leader>b', group = 'buffer' },
    { '<leader>f', group = 'find' },
    { '<leader>g', group = 'git' },
    { '<leader>l', group = 'language' },
    { '<leader>m', group = 'markdown' },
    { '<leader>q', group = 'quit/session' },
    { '<leader>r', group = 'reload' },
})
