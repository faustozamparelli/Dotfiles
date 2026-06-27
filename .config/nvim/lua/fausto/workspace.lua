local M = {}

local home = assert(vim.env.HOME, '$HOME is not set')

M.roots = {
    home .. '/Library/Mobile Documents/com~apple~CloudDocs/Documents/ShortTerm',
    home .. '/Library/Mobile Documents/com~apple~CloudDocs/Documents/LongTerm',
    home .. '/Developer',
    home .. '/.config',
}

local pruned_directories = {
    '.git',
    '.venv',
    '__pycache__',
    'build',
    'dist',
    'node_modules',
    'target',
}

local editable_application_types = {
    ['application/javascript'] = true,
    ['application/json'] = true,
    ['application/toml'] = true,
    ['application/x-empty'] = true,
    ['application/x-httpd-php'] = true,
    ['application/x-sh'] = true,
    ['application/x-shellscript'] = true,
    ['application/xhtml+xml'] = true,
    ['application/xml'] = true,
    ['application/yaml'] = true,
    ['inode/x-empty'] = true,
}

local function shellescape(path)
    return vim.fn.shellescape(path)
end

local function source_command()
    local roots = {}
    for _, root in ipairs(M.roots) do
        if vim.uv.fs_stat(root) then
            roots[#roots + 1] = shellescape(root)
        end
    end

    local commands = {}
    if #roots > 0 then
        local prune = {}
        for _, directory in ipairs(pruned_directories) do
            prune[#prune + 1] = '-name ' .. shellescape(directory)
        end

        commands[#commands + 1] = table.concat({
            'find',
            table.concat(roots, ' '),
            [[\( -type d \(]],
            table.concat(prune, ' -o '),
            [[\) -prune \) -o \( \( -type f -o -type d -o -type l \) -print \)]],
        }, ' ')
    end

    -- Home is intentionally shallow: a recursive scan would duplicate the
    -- focused roots and walk large, unrelated trees under ~/Library.
    commands[#commands + 1] = table.concat({
        'find',
        shellescape(home),
        '-mindepth 1 -maxdepth 1',
        [[\( -name .config -o -name Developer \) -prune -o]],
        [[\( -type f -o -type d -o -type l \) -print]],
    }, ' ')

    return table.concat(commands, '; ')
end

local function mime_type(path)
    local result = vim.system({ 'file', '--brief', '--mime-type', '--', path }, { text = true }):wait()
    if result.code ~= 0 then
        return nil
    end
    return vim.trim(result.stdout)
end

local function is_editable(path)
    local mime = mime_type(path)
    return mime and (vim.startswith(mime, 'text/') or editable_application_types[mime]) or false
end

local function open_external(path)
    local _, error_message = vim.ui.open(path)
    if error_message then
        vim.notify(error_message, vim.log.levels.ERROR)
    end
end

local function rename_tmux_window(path)
    if not vim.env.TMUX or not vim.env.TMUX_PANE then
        return
    end

    local name = vim.fn.fnamemodify(path, ':t')
    if name ~= '' then
        name = name:gsub('[:.]', '-')
        vim.system({ 'tmux', 'rename-window', '-t', vim.env.TMUX_PANE, name }):wait()
    end
end

function M.open_path(path)
    path = vim.trim(path or '')
    local stat = vim.uv.fs_stat(path)
    if not stat then
        vim.notify('Path no longer exists: ' .. path, vim.log.levels.WARN)
        return
    end

    -- Rename immediately from the fzf selection. BufEnter and DirChanged can
    -- occur after fzf has restored its temporary terminal buffer.
    rename_tmux_window(path)

    if stat.type == 'directory' then
        vim.cmd.cd(vim.fn.fnameescape(path))
        if vim.fn.executable('zoxide') == 1 then
            vim.system({ 'zoxide', 'add', path })
        end
        vim.cmd.edit(vim.fn.fnameescape(path))
        return
    end

    if stat.type == 'file' and is_editable(path) then
        vim.cmd.edit(vim.fn.fnameescape(path))
        return
    end

    open_external(path)
end

function M.pick()
    require('fzf-lua').fzf_exec(source_command(), {
        prompt = 'Anywhere> ',
        header = 'enter: edit file / open external file / switch project',
        fzf_opts = {
            ['--scheme'] = 'path',
            ['--tiebreak'] = 'end,index',
        },
        actions = {
            ['enter'] = function(selected)
                M.open_path(selected[1])
            end,
        },
    })
end

return M
