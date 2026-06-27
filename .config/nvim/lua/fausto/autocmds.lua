local group = vim.api.nvim_create_augroup('fausto_config', { clear = true })

vim.api.nvim_create_autocmd('TextYankPost', {
    group = group,
    desc = 'Highlight copied text',
    callback = function() vim.hl.on_yank() end,
})

vim.api.nvim_create_autocmd('BufWritePre', {
    group = group,
    desc = 'Format supported buffers before save',
    callback = function(args)
        if vim.bo[args.buf].filetype == 'python' or vim.bo[args.buf].filetype == 'c' or vim.bo[args.buf].filetype == 'cpp' then
            vim.lsp.buf.format({ bufnr = args.buf, async = false, timeout_ms = 3000 })
        end
    end,
})
