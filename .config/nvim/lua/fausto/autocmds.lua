local group = vim.api.nvim_create_augroup('fausto_config', { clear = true })

vim.api.nvim_create_autocmd('TextYankPost', {
    group = group,
    desc = 'Highlight copied text',
    callback = function() vim.hl.on_yank() end,
})

vim.api.nvim_create_autocmd('FocusLost', {
    group = group,
    desc = 'Save the current file when leaving the Neovim or Herdr pane',
    callback = function(args)
        if vim.bo[args.buf].modified and vim.bo[args.buf].buftype == '' and vim.api.nvim_buf_get_name(args.buf) ~= '' then
            vim.cmd('silent update')
        end
    end,
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

local function herdr_tab_name()
    if vim.env.HERDR_ENV ~= '1' or not vim.env.HERDR_TAB_ID then
        return
    end

    local path = vim.api.nvim_buf_get_name(0)
    local context
    if path ~= '' then
        context = vim.fn.fnamemodify(path, ':t')
    else
        context = vim.fn.fnamemodify(vim.fn.getcwd(), ':t')
    end

    if context == '' then
        context = vim.fn.fnamemodify(vim.fn.getcwd(), ':t')
    end
    context = context:gsub('[:.]', '-')

    vim.system({ 'herdr', 'tab', 'rename', vim.env.HERDR_TAB_ID, context }):wait()
end

vim.api.nvim_create_autocmd({ 'BufEnter', 'DirChanged', 'VimEnter' }, {
    group = group,
    desc = 'Keep the Herdr tab name aligned with the Neovim context',
    callback = function()
        vim.schedule(herdr_tab_name)
    end,
})
