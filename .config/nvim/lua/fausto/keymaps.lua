local map = vim.keymap.set
local fzf = require('fzf-lua')
local gitsigns = require('gitsigns')

local function opts(_, description)
    return { silent = true, desc = description }
end

local function open_lsp_results_in_side_pane(what)
    vim.fn.setqflist({}, ' ', what)
    vim.cmd.vsplit()
    vim.cmd.cfirst()
end

map({ 'n', 'i', 'v', 's' }, '<Esc>', function()
    if vim.v.hlsearch == 1 then
        vim.schedule(function()
            vim.cmd.nohlsearch()
        end)
    end

    return '<Esc>'
end, { expr = true, silent = true, desc = 'Escape and clear search highlight' })

map('i', '<Tab>', function()
    if vim.fn.pumvisible() == 1 then
        local selected = vim.fn.complete_info({ 'selected' }).selected
        return selected == -1 and '<C-n><C-y>' or '<C-y>'
    end

    return '<Tab>'
end, { expr = true, silent = true, desc = 'Accept top completion suggestion' })

map('n', '<leader><leader>', '<cmd>write<cr>', opts('nvim.file.save', 'Save file'))
map('n', '<leader>e', '<cmd>Oil<cr>', opts('nvim.file.oil', 'Open Oil'))
map('n', '-', '<cmd>Oil ..<cr>', opts('nvim.file.parent', 'Open parent directory'))
map('n', '<leader>d', function()
    local pattern = vim.fn.getreg('/')
    if pattern == '' then
        vim.notify('Search for a word first with /', vim.log.levels.WARN)
        return
    end

    vim.ui.input({ prompt = 'Replace matches with (Enter deletes): ' }, function(replacement)
        if replacement == nil then
            return
        end

        local bufnr = vim.api.nvim_get_current_buf()
        local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
        local matches = {}

        for _, found in ipairs(vim.fn.matchbufline(bufnr, pattern, 1, '$')) do
            local line = lines[found.lnum]
            local start_col = found.byteidx
            local end_col = found.byteidx + #found.text

            while start_col > 0 and not line:sub(start_col, start_col):match('%s') do
                start_col = start_col - 1
            end
            while end_col < #line and not line:sub(end_col + 1, end_col + 1):match('%s') do
                end_col = end_col + 1
            end

            local previous = matches[#matches]
            if not previous or previous.row ~= found.lnum - 1 or previous.start_col ~= start_col then
                matches[#matches + 1] = {
                    row = found.lnum - 1,
                    start_col = start_col,
                    end_col = end_col,
                }
            end
        end

        for index = #matches, 1, -1 do
            local match = matches[index]
            if index < #matches then
                vim.cmd.undojoin()
            end
            vim.api.nvim_buf_set_text(0, match.row, match.start_col, match.row, match.end_col, { replacement })
        end

        vim.notify(string.format('%s %d occurrence(s)', replacement == '' and 'Deleted' or 'Replaced', #matches))
    end)
end, opts('nvim.search.delete', 'Replace or delete WORD'))

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
map('n', 'K', vim.lsp.buf.hover, opts('nvim.language.hover', 'Open or focus symbol information'))
map('n', '<leader>lh', function()
    vim.lsp.buf.hover({
        focusable = true,
        max_height = math.max(1, vim.o.lines - 4),
        max_width = math.max(1, vim.o.columns - 4),
    })
end, opts('nvim.language.hover-large', 'Open large symbol information'))
map('n', 'gd', function()
    vim.lsp.buf.definition({ on_list = open_lsp_results_in_side_pane })
end, opts('nvim.language.definition', 'Open definition in side pane'))
map('n', 'gr', fzf.lsp_references, vim.tbl_extend('force', opts('nvim.language.references', 'Find references'), {
    nowait = true,
}))
map('n', 'gi', function()
    vim.lsp.buf.implementation({ on_list = open_lsp_results_in_side_pane })
end, opts('nvim.language.implementation', 'Open implementation in side pane'))
map('n', 'gy', function()
    vim.lsp.buf.type_definition({ on_list = open_lsp_results_in_side_pane })
end, opts('nvim.language.type-definition', 'Open type definition in side pane'))
map('n', 'gs', vim.lsp.buf.document_symbol, opts('nvim.language.document-symbols', 'Document symbols'))
map('n', '<leader>le', function()
    local diagnostics = vim.diagnostic.get(nil, {
        severity = vim.diagnostic.severity.ERROR,
    })
    table.sort(diagnostics, function(a, b)
        if a.bufnr ~= b.bufnr then
            return a.bufnr < b.bufnr
        end
        if a.lnum ~= b.lnum then
            return a.lnum < b.lnum
        end
        return a.col < b.col
    end)

    local lines = {}
    for _, diagnostic in ipairs(diagnostics) do
        local path = vim.api.nvim_buf_get_name(diagnostic.bufnr)
        if path == '' then
            path = '[No Name]'
        else
            path = vim.fn.fnamemodify(path, ':.')
        end

        local severity = vim.diagnostic.severity[diagnostic.severity] or 'UNKNOWN'
        local source = diagnostic.source and (' [' .. diagnostic.source .. ']') or ''
        local message = diagnostic.message:gsub('\r?\n', ' ')
        lines[#lines + 1] = string.format(
            '%s:%d:%d: %s%s: %s',
            path,
            diagnostic.lnum + 1,
            diagnostic.col + 1,
            severity,
            source,
            message
        )
    end

    if #lines == 0 then
        vim.notify('No diagnostics to copy')
        return
    end

    vim.fn.setreg('+', table.concat(lines, '\n'))
    vim.notify(string.format('Copied %d diagnostic(s) to clipboard', #lines))
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
    require('which-key').show({ keys = '<leader>', mode = 'n', delay = 0 })
end, opts('nvim.help.keys', 'Show leader keymaps'))

for key, direction in pairs({ h = 'h', j = 'j', k = 'k', l = 'l' }) do
    map('n', '<A-' .. key .. '>', '<C-w>' .. direction, opts('nvim.window.' .. key, 'Move to adjacent pane'))
    map('t', '<A-' .. key .. '>', '<C-\\><C-n><C-w>' .. direction, opts('nvim.terminal-window.' .. key, 'Move to adjacent pane'))
end

map({ 'n', 'x', 'o' }, 'H', '^', opts('nvim.motion.line-start', 'Line start'))
map({ 'n', 'x', 'o' }, 'L', '$', opts('nvim.motion.line-end', 'Line end'))
map('n', 'U', '<C-r>', opts('nvim.edit.redo', 'Redo'))
map('x', 'J', ":move '>+1<cr>gv=gv", opts('nvim.visual.move-down', 'Move selection down'))
map('x', 'K', ":move '<-2<cr>gv=gv", opts('nvim.visual.move-up', 'Move selection up'))
