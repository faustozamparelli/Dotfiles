local M = {}

local function target_under_cursor()
    local line = vim.api.nvim_get_current_line()
    local column = vim.api.nvim_win_get_cursor(0)[2] + 1
    local from = 1

    while true do
        local first, last = line:find('%b[]%b()', from)
        if not first then
            break
        end
        if column >= first and column <= last then
            local _, label_end = line:find('%b[]', first)
            local destination = line:sub(label_end + 2, last - 1)
            return destination:match('^%s*<([^>]+)>') or destination:match('^%s*([^%s]+)')
        end
        from = last + 1
    end

    for first, destination, last in line:gmatch('()<(https?://[^>]+)>()') do
        if column >= first and column < last then
            return destination
        end
    end
end

function M.follow()
    local target = target_under_cursor()
    if not target then
        vim.cmd('normal! gf')
        return
    end

    if target:match('^https?://') then
        vim.system({ 'open', '-a', 'Helium', target }, { text = true }, function(result)
            if result.code ~= 0 then
                vim.schedule(function()
                    local message = vim.trim(result.stderr or '')
                    vim.notify(message ~= '' and message or 'Could not open link in Helium', vim.log.levels.ERROR)
                end)
            end
        end)
        return
    end

    if target:match('^[%a][%w+.-]*:') then
        local _, err = vim.ui.open(target)
        if err then
            vim.notify(err, vim.log.levels.ERROR)
        end
        return
    end

    local path = target:match('^[^#]*')
    if path == '' then
        path = vim.api.nvim_buf_get_name(0)
    elseif path:sub(1, 1) == '~' then
        path = vim.fn.expand(path)
    elseif not vim.startswith(path, '/') then
        local current_file = vim.api.nvim_buf_get_name(0)
        local directory = current_file ~= '' and vim.fs.dirname(current_file) or vim.fn.getcwd()
        path = vim.fs.joinpath(directory, path)
    end

    if vim.fn.filereadable(path) == 0 then
        vim.notify('Markdown link target not found: ' .. path, vim.log.levels.WARN)
        return
    end
    vim.cmd.edit(vim.fn.fnameescape(path))
end

function M.setup()
    vim.api.nvim_create_autocmd('FileType', {
        pattern = 'markdown',
        desc = 'Follow Markdown links with gf',
        callback = function(args)
            vim.keymap.set('n', 'gf', M.follow, {
                buffer = args.buf,
                silent = true,
                desc = 'Follow Markdown link or file under cursor',
            })
        end,
    })
end

return M
