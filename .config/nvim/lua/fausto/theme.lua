local M = {}

local current
local checking = false

local function system_is_dark()
    if vim.fn.has('mac') == 1 then
        local result = vim.system({ 'defaults', 'read', '-g', 'AppleInterfaceStyle' }, { text = true }):wait()
        return result.code == 0 and result.stdout:match('Dark') ~= nil
    end

    return vim.o.background == 'dark'
end

local function set_highlights(dark)
    local background = dark and '#000000' or '#ffffff'
    local foreground = dark and '#e6e6e6' or '#171717'
    local subtle = dark and '#111827' or '#edf2f7'

    for _, group in ipairs({ 'Normal', 'NormalFloat', 'SignColumn', 'EndOfBuffer' }) do
        vim.api.nvim_set_hl(0, group, { bg = background, fg = foreground })
    end

    vim.api.nvim_set_hl(0, 'CursorLine', { bg = subtle })
    vim.api.nvim_set_hl(0, 'CursorLineNr', { bg = subtle, fg = dark and '#67e8f9' or '#0369a1', bold = true })
    vim.api.nvim_set_hl(0, 'FloatBorder', { bg = background, fg = dark and '#22d3ee' or '#0284c7' })
    vim.api.nvim_set_hl(0, 'LineNr', { bg = background, fg = dark and '#525252' or '#a3a3a3' })
    vim.api.nvim_set_hl(0, 'StatusLine', { bg = background, fg = dark and '#a3a3a3' or '#525252' })
    vim.api.nvim_set_hl(0, 'StatusLineNC', { bg = background, fg = dark and '#525252' or '#a3a3a3' })
    vim.api.nvim_set_hl(0, 'Visual', { bg = dark and '#164e63' or '#bae6fd' })
    vim.api.nvim_set_hl(0, 'MarkdownPersistentHighlight', {
        bg = dark and '#854d0e' or '#fde047',
        fg = dark and '#fef9c3' or '#422006',
    })

    -- Keep rendered Markdown in the same restrained palette as the editor.
    vim.api.nvim_set_hl(0, 'RenderMarkdownH1', { fg = dark and '#a5f3fc' or '#075985', bold = true })
    vim.api.nvim_set_hl(0, 'RenderMarkdownH2', { fg = dark and '#67e8f9' or '#0369a1', bold = true })
    vim.api.nvim_set_hl(0, 'RenderMarkdownH3', { fg = dark and '#22d3ee' or '#0284c7', bold = true })
    vim.api.nvim_set_hl(0, 'RenderMarkdownH4', { fg = dark and '#d4d4d4' or '#404040', bold = true })
    vim.api.nvim_set_hl(0, 'RenderMarkdownH5', { fg = dark and '#a3a3a3' or '#525252', italic = true })
    vim.api.nvim_set_hl(0, 'RenderMarkdownH6', { fg = dark and '#737373' or '#737373', italic = true })
    vim.api.nvim_set_hl(0, 'RenderMarkdownMuted', { fg = dark and '#737373' or '#737373' })
    vim.api.nvim_set_hl(0, 'RenderMarkdownChecked', { fg = dark and '#a3a3a3' or '#525252' })
    vim.api.nvim_set_hl(0, 'RenderMarkdownCode', { bg = subtle })
    vim.api.nvim_set_hl(0, 'RenderMarkdownCodeBorder', { fg = dark and '#404040' or '#d4d4d4', bg = subtle })
    vim.api.nvim_set_hl(0, 'RenderMarkdownCodeInline', { fg = foreground, bg = subtle })
end

function M.apply(dark)
    local appearance = dark and 'dark' or 'light'
    if current == appearance then
        return
    end

    current = appearance
    vim.o.background = appearance
    vim.cmd.colorscheme(dark and 'habamax' or 'morning')
    set_highlights(dark)
end

local function refresh_async()
    if checking or vim.fn.has('mac') ~= 1 then
        return
    end

    checking = true
    vim.system({ 'defaults', 'read', '-g', 'AppleInterfaceStyle' }, { text = true }, function(result)
        checking = false
        local dark = result.code == 0 and result.stdout:match('Dark') ~= nil
        vim.schedule(function()
            if vim.v.exiting == vim.NIL then
                M.apply(dark)
            end
        end)
    end)
end

function M.setup()
    M.apply(system_is_dark())

    if vim.fn.has('mac') ~= 1 then
        return
    end

    local timer = vim.uv.new_timer()
    timer:start(2000, 2000, vim.schedule_wrap(refresh_async))

    vim.api.nvim_create_autocmd('VimLeavePre', {
        callback = function()
            timer:stop()
            timer:close()
        end,
        once = true,
    })
end

return M
