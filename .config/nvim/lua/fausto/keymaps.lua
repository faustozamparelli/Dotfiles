local map = vim.keymap.set
local fzf = require('fzf-lua')
local gitsigns = require('gitsigns')

local function opts(_, description)
    return { silent = true, desc = description }
end

local function open_lsp_results_in_current_window(what)
    vim.fn.setqflist({}, ' ', what)
    vim.cmd.cfirst()
end

local function current_buffer_directory()
    local oil_ok, oil = pcall(require, 'oil')
    if oil_ok then
        local oil_directory = oil.get_current_dir()
        if oil_directory then
            return oil_directory
        end
    end

    local path = vim.api.nvim_buf_get_name(0)
    if vim.bo.buftype == '' and path ~= '' then
        return vim.fn.fnamemodify(path, ':p:h')
    end

    return vim.fn.getcwd()
end

local function run_herdr(command, failure_message)
    if vim.env.HERDR_ENV ~= '1' or not vim.env.HERDR_PANE_ID then
        vim.notify('This action needs Neovim to be running inside Herdr', vim.log.levels.WARN)
        return
    end

    vim.system(command, {}, function(result)
        if result.code ~= 0 then
            vim.schedule(function()
                local message = vim.trim(result.stderr or '')
                vim.notify(message ~= '' and message or failure_message, vim.log.levels.ERROR)
            end)
        end
    end)
end

local function open_codex()
    run_herdr({
        vim.fn.expand('~/.config/herdr/open-codex-tab'),
        current_buffer_directory(),
    }, 'Could not open a Codex tab in Herdr')
end

local function split_herdr_pane(direction)
    run_herdr({
        'herdr',
        'pane',
        'split',
        '--current',
        '--direction',
        direction,
        '--cwd',
        current_buffer_directory(),
        '--focus',
    }, 'Could not split the Herdr pane')
end

local function focus_window_or_herdr(direction, nvim_direction)
    local window = vim.api.nvim_get_current_win()
    vim.cmd.wincmd(nvim_direction)
    if vim.api.nvim_get_current_win() ~= window then
        return
    end

    run_herdr({
        'herdr',
        'pane',
        'focus',
        '--current',
        '--direction',
        direction,
    }, 'Could not focus the adjacent Herdr pane')
end

map({ 'n', 'i', 'v', 's' }, '<Esc>', function()
    if vim.v.hlsearch == 1 then
        vim.schedule(function()
            vim.cmd.nohlsearch()
        end)
    end

    return '<Esc>'
end, { expr = true, silent = true, desc = 'Escape and clear search highlight' })

map('n', 'cm', 'gcc', { remap = true, silent = true, desc = 'Toggle comment on current line' })
map('x', 'cm', 'gc', { remap = true, silent = true, desc = 'Toggle comment' })

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
map('n', '<leader>ac', open_codex, opts('nvim.ai.codex', 'Open Codex in a Herdr tab'))
local function split_herdr_right()
    split_herdr_pane('right')
end

local function split_herdr_down()
    split_herdr_pane('down')
end

map('n', '<D-b>', split_herdr_right, opts('nvim.herdr.split-right-command', 'Split Herdr pane right'))
map('n', '<leader>pv', split_herdr_right, opts('nvim.herdr.split-right', 'Split Herdr pane right'))
map('n', '<D-n>', split_herdr_down, opts('nvim.herdr.split-down-command', 'Split Herdr pane down'))
map('n', '<leader>ph', split_herdr_down, opts('nvim.herdr.split-down', 'Split Herdr pane down'))
local function replace_plain(text, target, replacement)
    local pieces = {}
    local position = 1
    local count = 0

    while true do
        local match_start, match_end = text:find(target, position, true)
        if not match_start then
            pieces[#pieces + 1] = text:sub(position)
            break
        end

        pieces[#pieces + 1] = text:sub(position, match_start - 1)
        pieces[#pieces + 1] = replacement
        position = match_end + 1
        count = count + 1
    end

    return table.concat(pieces), count
end

local function inclusive_end_col(line, column)
    local end_col = math.min(column, #line)

    while end_col < #line do
        local byte = line:byte(end_col + 1)
        if not byte or byte < 0x80 or byte >= 0xC0 then
            break
        end
        end_col = end_col + 1
    end

    return end_col
end

map('x', '<leader>r', function()
    local bufnr = vim.api.nvim_get_current_buf()
    local visual_mode = vim.fn.mode()
    local region = vim.fn.getregionpos(vim.fn.getpos('v'), vim.fn.getpos('.'), {
        type = visual_mode,
        exclusive = vim.o.selection == 'exclusive',
        eol = true,
    })

    vim.ui.input({ prompt = 'Word to change: ' }, function(target)
        if target == nil then
            return
        end

        if target == '' then
            vim.notify('Enter a word to change', vim.log.levels.WARN)
            return
        end

        vim.ui.input({ prompt = 'Replace with: ' }, function(replacement)
            if replacement == nil or not vim.api.nvim_buf_is_valid(bufnr) then
                return
            end

            if replacement == '' then
                vim.notify('Enter replacement text', vim.log.levels.WARN)
                return
            end

            local count = 0

            if visual_mode == 'V' then
                local start_row = region[1][1][2] - 1
                local end_row = region[#region][2][2]
                local selected = vim.api.nvim_buf_get_lines(bufnr, start_row, end_row, false)
                local changed
                changed, count = replace_plain(table.concat(selected, '\n'), target, replacement)
                if count > 0 then
                    vim.api.nvim_buf_set_lines(
                        bufnr,
                        start_row,
                        end_row,
                        false,
                        vim.split(changed, '\n', { plain = true })
                    )
                end
            elseif visual_mode == '\22' then
                for index = #region, 1, -1 do
                    local start_pos, end_pos = unpack(region[index])
                    local row = start_pos[2] - 1
                    local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1]
                    local start_col = math.min(start_pos[3] - 1, #line)
                    local end_col = inclusive_end_col(line, end_pos[3])
                    local selected = line:sub(start_col + 1, end_col)
                    local changed, replacements = replace_plain(selected, target, replacement)

                    if replacements > 0 then
                        vim.api.nvim_buf_set_text(bufnr, row, start_col, row, end_col, { changed })
                        count = count + replacements
                    end
                end
            else
                local start_pos = region[1][1]
                local end_pos = region[#region][2]
                local start_row = start_pos[2] - 1
                local end_row = end_pos[2] - 1
                local start_line = vim.api.nvim_buf_get_lines(bufnr, start_row, start_row + 1, false)[1]
                local end_line = vim.api.nvim_buf_get_lines(bufnr, end_row, end_row + 1, false)[1]
                local start_col = math.min(start_pos[3] - 1, #start_line)
                local end_col = inclusive_end_col(end_line, end_pos[3])
                local selected = vim.api.nvim_buf_get_text(bufnr, start_row, start_col, end_row, end_col, {})
                local changed
                changed, count = replace_plain(table.concat(selected, '\n'), target, replacement)

                if count > 0 then
                    vim.api.nvim_buf_set_text(
                        bufnr,
                        start_row,
                        start_col,
                        end_row,
                        end_col,
                        vim.split(changed, '\n', { plain = true })
                    )
                end
            end

            vim.notify(string.format('Replaced %d occurrence(s)', count))
        end)
    end)
end, opts('nvim.selection.replace', 'Replace text in selection'))

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
map('n', '<leader>ls', fzf.lsp_workspace_symbols, opts('nvim.language.workspace-symbols', 'Workspace symbols'))
map('n', '<leader>lp', require('fausto.python_source').open, opts('nvim.language.python-source', 'Open Python source'))
map('n', 'K', vim.lsp.buf.hover, opts('nvim.language.hover', 'Open or focus symbol information'))
map('n', '<leader>lh', function()
    vim.lsp.buf.hover({
        focusable = true,
        max_height = math.max(1, vim.o.lines - 4),
        max_width = math.max(1, vim.o.columns - 4),
    })
end, opts('nvim.language.hover-large', 'Open large symbol information'))
map('n', 'gd', function()
    vim.lsp.buf.definition({ on_list = open_lsp_results_in_current_window })
end, opts('nvim.language.definition', 'Open definition'))
map('n', 'gr', fzf.lsp_references, vim.tbl_extend('force', opts('nvim.language.references', 'Find references'), {
    nowait = true,
}))
map('n', 'gi', function()
    vim.lsp.buf.implementation({ on_list = open_lsp_results_in_current_window })
end, opts('nvim.language.implementation', 'Open implementation'))
map('n', 'gy', function()
    vim.lsp.buf.type_definition({ on_list = open_lsp_results_in_current_window })
end, opts('nvim.language.type-definition', 'Open type definition'))
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
map('n', '<leader>lE', function()
    local diagnostics = vim.diagnostic.get(nil, {
        severity = vim.diagnostic.severity.ERROR,
    })
    if #diagnostics == 0 then
        vim.notify('No errors')
        return
    end

    vim.fn.setqflist({}, ' ', {
        title = 'All diagnostic errors',
        items = vim.diagnostic.toqflist(diagnostics),
    })
    vim.cmd.copen()
end, opts('nvim.language.all-errors', 'Show all errors'))
map({ 'n', 'x' }, '<leader>lf', function()
    vim.lsp.buf.format({ async = false, timeout_ms = 3000 })
end, opts('nvim.language.format', 'Format buffer'))

map('n', '<leader>bl', '<cmd>bnext<cr>', opts('nvim.buffer.next', 'Next buffer'))
map('n', '<leader>bh', '<cmd>bprevious<cr>', opts('nvim.buffer.previous', 'Previous buffer'))
map('n', '<leader>bk', '<cmd>bdelete<cr>', opts('nvim.buffer.delete', 'Delete buffer'))
map('n', '<leader>rr', '<cmd>restart<cr>', opts('nvim.reload.config', 'Reload Neovim configuration'))
map('n', '<leader>qq', '<cmd>quit<cr>', opts('nvim.quit.buffer', 'Quit window'))
map('n', '<leader>qa', '<cmd>quitall<cr>', opts('nvim.quit.all', 'Quit Neovim'))
map('n', '<leader>?', function()
    require('which-key').show({ keys = '<leader>', mode = 'n', delay = 0 })
end, opts('nvim.help.keys', 'Show leader keymaps'))

for key, direction in pairs({ h = 'left', j = 'down', k = 'up', l = 'right' }) do
    map('n', '<A-' .. key .. '>', function()
        focus_window_or_herdr(direction, key)
    end, opts('nvim.window.' .. key, 'Move to adjacent Neovim window or Herdr pane'))
end

map({ 'n', 'x', 'o' }, 'H', '^', opts('nvim.motion.line-start', 'Line start'))
map({ 'n', 'x', 'o' }, 'L', '$', opts('nvim.motion.line-end', 'Line end'))
map('n', 'U', '<C-r>', opts('nvim.edit.redo', 'Redo'))
map('x', 'J', ":move '>+1<cr>gv=gv", opts('nvim.visual.move-down', 'Move selection down'))
map('x', 'K', ":move '<-2<cr>gv=gv", opts('nvim.visual.move-up', 'Move selection up'))
