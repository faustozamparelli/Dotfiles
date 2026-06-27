local map = vim.keymap.set
local fzf = require('fzf-lua')
local gitsigns = require('gitsigns')

local function opts(id, description)
    return { silent = true, desc = description .. ' [km:' .. id .. ']' }
end

map({ 'n', 'i', 'v', 's' }, '<Esc>', function()
    if vim.v.hlsearch == 1 then
        vim.schedule(function()
            vim.cmd.nohlsearch()
        end)
    end

    return '<Esc>'
end, { expr = true, silent = true, desc = 'Escape and clear search highlight' })

map('n', '<leader><leader>', '<cmd>write<cr>', opts('nvim.file.save', 'Save file'))
map('n', '<leader>e', '<cmd>Oil<cr>', opts('nvim.file.oil', 'Open Oil'))
map('n', '-', '<cmd>Oil ..<cr>', opts('nvim.file.parent', 'Open parent directory'))

map('n', '<leader>ff', fzf.files, opts('nvim.find.files', 'Find files'))
map('n', '<leader>fa', require('fausto.workspace').pick, opts('nvim.find.anywhere', 'Find anywhere'))
map('n', '<leader>fg', fzf.live_grep, opts('nvim.find.grep', 'Search project text'))
map('n', '<leader>fb', fzf.buffers, opts('nvim.find.buffers', 'Find buffers'))
map('n', '<leader>fr', fzf.oldfiles, opts('nvim.find.recent', 'Find recent files'))
map('n', '<leader>fh', fzf.helptags, opts('nvim.find.help', 'Search help'))
map('n', '<leader>fF', function()
    local path = vim.api.nvim_buf_get_name(0)
    if path == '' then
        vim.notify('The current buffer has no file to reveal', vim.log.levels.WARN)
        return
    end

    vim.system({ 'open', '-R', path }, {}, function(result)
        if result.code ~= 0 then
            vim.schedule(function()
                vim.notify('Finder could not reveal the current file', vim.log.levels.ERROR)
            end)
        end
    end)
end, opts('nvim.find.finder', 'Reveal current file in Finder'))

map('n', '<leader>mp', '<cmd>RenderMarkdown buf_toggle<cr>', opts('nvim.markdown.preview', 'Toggle rendered Markdown'))
map('n', '<leader>mb', function()
    local path = vim.api.nvim_buf_get_name(0)
    if path == '' or vim.bo.buftype ~= '' then
        vim.notify('The current buffer is not a file', vim.log.levels.WARN)
        return
    end
    if vim.bo.filetype ~= 'markdown' then
        vim.notify('The current file is not Markdown', vim.log.levels.WARN)
        return
    end

    vim.cmd.write()
    vim.system({ 'open', '-a', 'Helium', path }, {}, function(result)
        if result.code ~= 0 then
            vim.schedule(function()
                local message = vim.trim(result.stderr or '')
                vim.notify(message ~= '' and message or 'Could not open Markdown in Helium', vim.log.levels.ERROR)
            end)
        end
    end)
end, opts('nvim.markdown.browser', 'Open Markdown in Helium'))

map('n', '<leader>gs', fzf.git_status, opts('nvim.git.status', 'Git status'))
map('n', '<leader>gb', gitsigns.blame_line, opts('nvim.git.blame', 'Blame line'))
map('n', '<leader>gd', gitsigns.diffthis, opts('nvim.git.diff', 'Diff file'))
map('n', '<leader>gn', gitsigns.next_hunk, opts('nvim.git.next-hunk', 'Next hunk'))
map('n', '<leader>gp', gitsigns.prev_hunk, opts('nvim.git.prev-hunk', 'Previous hunk'))

map('n', '<leader>lr', vim.lsp.buf.rename, opts('nvim.language.rename', 'Rename symbol'))
map({ 'n', 'x' }, '<leader>la', vim.lsp.buf.code_action, opts('nvim.language.action', 'Code action'))
map('n', '<leader>ld', fzf.diagnostics_workspace, opts('nvim.language.diagnostics', 'Workspace diagnostics'))
map('n', '<leader>le', function()
    vim.cmd('redir @+')
    vim.cmd('silent messages')
    vim.cmd('redir END')
    vim.notify('Copied Neovim messages to clipboard')
end, opts('nvim.language.copy-errors', 'Copy error messages'))
map({ 'n', 'x' }, '<leader>lf', function()
    vim.lsp.buf.format({ async = false, timeout_ms = 3000 })
end, opts('nvim.language.format', 'Format buffer'))

map('n', '<leader>bl', '<cmd>bnext<cr>', opts('nvim.buffer.next', 'Next buffer'))
map('n', '<leader>bh', '<cmd>bprevious<cr>', opts('nvim.buffer.previous', 'Previous buffer'))
map('n', '<leader>bd', '<cmd>bdelete<cr>', opts('nvim.buffer.delete', 'Delete buffer'))
map('n', '<leader>rr', '<cmd>restart<cr>', opts('nvim.reload.config', 'Reload Neovim configuration'))
map('n', '<leader>qq', '<cmd>quit<cr>', opts('nvim.quit.buffer', 'Quit window'))
map('n', '<leader>qa', '<cmd>quitall<cr>', opts('nvim.quit.all', 'Quit Neovim'))
map('n', '<leader>?', function()
    require('which-key').show({ global = true })
end, opts('nvim.help.keys', 'Show keymaps'))

map({ 'n', 'x', 'o' }, 'H', '^', opts('nvim.motion.line-start', 'Line start'))
map({ 'n', 'x', 'o' }, 'L', '$', opts('nvim.motion.line-end', 'Line end'))
map('n', 'U', '<C-r>', opts('nvim.edit.redo', 'Redo'))
map('x', 'J', ":move '>+1<cr>gv=gv", opts('nvim.visual.move-down', 'Move selection down'))
map('x', 'K', ":move '<-2<cr>gv=gv", opts('nvim.visual.move-up', 'Move selection up'))
