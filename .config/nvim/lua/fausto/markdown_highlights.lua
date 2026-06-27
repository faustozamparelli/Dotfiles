local M = {}

local namespace = vim.api.nvim_create_namespace('fausto_markdown_highlights')
local storage_dir = vim.fn.stdpath('data') .. '/markdown-highlights'
local loaded = {}
local suppress_mode_change = {}

local function is_markdown(buf)
    return vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].filetype == 'markdown'
end

local function storage_path(buf)
    local path = vim.api.nvim_buf_get_name(buf)
    if path == '' then
        return nil
    end
    return storage_dir .. '/' .. vim.fn.sha256(vim.fs.normalize(path)) .. '.json'
end

local function marks(buf)
    local result = {}
    for _, mark in ipairs(vim.api.nvim_buf_get_extmarks(buf, namespace, 0, -1, { details = true })) do
        local details = mark[4]
        result[#result + 1] = {
            start_row = mark[2],
            start_col = mark[3],
            end_row = details.end_row,
            end_col = details.end_col,
        }
    end
    table.sort(result, function(a, b)
        if a.start_row ~= b.start_row then
            return a.start_row < b.start_row
        end
        return a.start_col < b.start_col
    end)
    return result
end

local function save(buf)
    local path = storage_path(buf)
    if not path then
        return
    end

    vim.fn.mkdir(storage_dir, 'p')
    local payload = {
        version = 1,
        source = vim.api.nvim_buf_get_name(buf),
        highlights = marks(buf),
    }
    vim.fn.writefile({ vim.json.encode(payload) }, path)
end

local function add(buf, range)
    vim.api.nvim_buf_set_extmark(buf, namespace, range.start_row, range.start_col, {
        end_row = range.end_row,
        end_col = range.end_col,
        hl_group = 'MarkdownPersistentHighlight',
        hl_mode = 'combine',
        priority = 250,
        right_gravity = false,
        end_right_gravity = true,
    })
end

local function load(buf)
    if loaded[buf] or not is_markdown(buf) then
        return
    end
    loaded[buf] = true

    local path = storage_path(buf)
    if not path or vim.fn.filereadable(path) == 0 then
        return
    end

    local ok, payload = pcall(vim.json.decode, table.concat(vim.fn.readfile(path), '\n'))
    if not ok or type(payload) ~= 'table' or type(payload.highlights) ~= 'table' then
        vim.notify('Could not load Markdown highlights for this file', vim.log.levels.WARN)
        return
    end

    local line_count = vim.api.nvim_buf_line_count(buf)
    for _, range in ipairs(payload.highlights) do
        if type(range) == 'table'
            and type(range.start_row) == 'number'
            and type(range.start_col) == 'number'
            and type(range.end_row) == 'number'
            and type(range.end_col) == 'number'
            and range.start_row >= 0
            and range.end_row >= range.start_row
            and range.end_row < line_count
        then
            local start_line = vim.api.nvim_buf_get_lines(buf, range.start_row, range.start_row + 1, false)[1]
            local end_line = vim.api.nvim_buf_get_lines(buf, range.end_row, range.end_row + 1, false)[1]
            if range.start_col >= 0
                and range.start_col <= #start_line
                and range.end_col >= 0
                and range.end_col <= #end_line
            then
                add(buf, range)
            end
        end
    end
end

local function position_before(a, b)
    return a[2] < b[2] or (a[2] == b[2] and a[3] <= b[3])
end

local function selection_range(buf, from_marks)
    local mode = from_marks and vim.fn.visualmode() or vim.fn.mode()
    if mode == '\22' then
        vim.notify('Block selections cannot be saved as one Markdown highlight', vim.log.levels.WARN)
        return nil
    end

    local first = vim.fn.getpos(from_marks and "'<" or 'v')
    local last = vim.fn.getpos(from_marks and "'>" or '.')
    if first[2] == 0 or last[2] == 0 then
        return nil
    end
    if not position_before(first, last) then
        first, last = last, first
    end

    if mode == 'V' then
        first[3] = 1
        last[3] = #vim.api.nvim_buf_get_lines(buf, last[2] - 1, last[2], false)[1]
        return {
            start_row = first[2] - 1,
            start_col = 0,
            end_row = last[2] - 1,
            end_col = last[3],
        }
    end

    local line = vim.api.nvim_buf_get_lines(buf, last[2] - 1, last[2], false)[1]
    local character = vim.fn.strcharpart(line:sub(last[3]), 0, 1)
    return {
        start_row = first[2] - 1,
        start_col = first[3] - 1,
        end_row = last[2] - 1,
        end_col = last[3] - 1 + #character,
    }
end

local function same_range(mark, range)
    local details = mark[4]
    return mark[2] == range.start_row
        and mark[3] == range.start_col
        and details.end_row == range.end_row
        and details.end_col == range.end_col
end

local function mark_range(mark)
    return {
        start_row = mark[2],
        start_col = mark[3],
        end_row = mark[4].end_row,
        end_col = mark[4].end_col,
    }
end

local function position_less(row_a, col_a, row_b, col_b)
    return row_a < row_b or (row_a == row_b and col_a < col_b)
end

local function overlaps(a, b)
    return position_less(a.start_row, a.start_col, b.end_row, b.end_col)
        and position_less(b.start_row, b.start_col, a.end_row, a.end_col)
end

local function merge(a, b)
    local result = vim.deepcopy(a)
    if position_less(b.start_row, b.start_col, result.start_row, result.start_col) then
        result.start_row = b.start_row
        result.start_col = b.start_col
    end
    if position_less(result.end_row, result.end_col, b.end_row, b.end_col) then
        result.end_row = b.end_row
        result.end_col = b.end_col
    end
    return result
end

local function normalize(buf)
    local extmarks = vim.api.nvim_buf_get_extmarks(buf, namespace, 0, -1, { details = true })
    if #extmarks < 2 then
        return
    end

    local normalized = {}
    for _, mark in ipairs(extmarks) do
        local range = mark_range(mark)
        local previous = normalized[#normalized]
        if previous and overlaps(previous, range) then
            normalized[#normalized] = merge(previous, range)
        else
            normalized[#normalized + 1] = range
        end
    end

    if #normalized == #extmarks then
        return
    end
    vim.api.nvim_buf_clear_namespace(buf, namespace, 0, -1)
    for _, range in ipairs(normalized) do
        add(buf, range)
    end
    save(buf)
end

local function toggle(buf, range)
    if not range or (range.start_row == range.end_row and range.start_col == range.end_col) then
        return
    end

    for _, mark in ipairs(vim.api.nvim_buf_get_extmarks(buf, namespace, 0, -1, { details = true })) do
        if same_range(mark, range) then
            vim.api.nvim_buf_del_extmark(buf, namespace, mark[1])
            save(buf)
            return
        end
    end

    local merged = range
    for _, mark in ipairs(vim.api.nvim_buf_get_extmarks(buf, namespace, 0, -1, { details = true })) do
        local existing = mark_range(mark)
        if overlaps(existing, merged) then
            merged = merge(existing, merged)
            vim.api.nvim_buf_del_extmark(buf, namespace, mark[1])
        end
    end

    add(buf, merged)
    save(buf)
end

function M.mouse_release()
    local buf = vim.api.nvim_get_current_buf()
    if not is_markdown(buf) then
        return
    end

    toggle(buf, selection_range(buf, false))
    suppress_mode_change[buf] = true
    local escape = vim.api.nvim_replace_termcodes('<Esc>', true, false, true)
    vim.api.nvim_feedkeys(escape, 'n', false)
end

function M.remove_at_mouse()
    local mouse = vim.fn.getmousepos()
    if mouse.winid == 0 or mouse.line == 0 or mouse.column == 0 or not vim.api.nvim_win_is_valid(mouse.winid) then
        return
    end

    local buf = vim.api.nvim_win_get_buf(mouse.winid)
    if not is_markdown(buf) then
        return
    end

    local row = mouse.line - 1
    local col = mouse.column - 1
    local removed = false
    for _, mark in ipairs(vim.api.nvim_buf_get_extmarks(buf, namespace, 0, -1, { details = true })) do
        local range = mark_range(mark)
        local starts_before = not position_less(row, col, range.start_row, range.start_col)
        local ends_after = position_less(row, col, range.end_row, range.end_col)
        if starts_before and ends_after then
            vim.api.nvim_buf_del_extmark(buf, namespace, mark[1])
            removed = true
        end
    end
    if removed then
        save(buf)
    end
end

function M.setup()
    local group = vim.api.nvim_create_augroup('fausto_markdown_highlights', { clear = true })

    vim.api.nvim_create_autocmd('FileType', {
        group = group,
        pattern = 'markdown',
        desc = 'Restore persistent Markdown highlights',
        callback = function(args)
            load(args.buf)
            normalize(args.buf)
        end,
    })

    vim.api.nvim_create_autocmd('BufWritePost', {
        group = group,
        pattern = { '*.md', '*.markdown' },
        desc = 'Save updated Markdown highlight positions',
        callback = function(args)
            if loaded[args.buf] then
                save(args.buf)
            end
        end,
    })

    vim.api.nvim_create_autocmd('BufWipeout', {
        group = group,
        desc = 'Forget unloaded Markdown highlight state',
        callback = function(args)
            loaded[args.buf] = nil
            suppress_mode_change[args.buf] = nil
        end,
    })

    vim.api.nvim_create_autocmd('ModeChanged', {
        group = group,
        desc = 'Toggle a completed keyboard Markdown selection',
        callback = function(args)
            local old_mode = vim.v.event.old_mode or ''
            local new_mode = vim.v.event.new_mode or ''
            if not old_mode:match('^[vV\22sS\19]') or new_mode:match('^[vV\22sS\19]') then
                return
            end
            if suppress_mode_change[args.buf] then
                suppress_mode_change[args.buf] = nil
                return
            end
            if is_markdown(args.buf) then
                toggle(args.buf, selection_range(args.buf, true))
            end
        end,
    })

    vim.keymap.set('x', '<LeftRelease>', function()
        local release = vim.api.nvim_replace_termcodes('<LeftRelease>', true, false, true)
        vim.api.nvim_feedkeys(release, 'n', false)
        vim.schedule(M.mouse_release)
    end, { silent = true, desc = 'Toggle persistent Markdown highlight' })

    vim.keymap.set('n', '<RightMouse>', M.remove_at_mouse, {
        silent = true,
        desc = 'Remove persistent Markdown highlight under mouse',
    })

    vim.schedule(function()
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            if is_markdown(buf) then
                if loaded[buf] then
                    normalize(buf)
                else
                    load(buf)
                    normalize(buf)
                end
            end
        end
    end)
end

return M
