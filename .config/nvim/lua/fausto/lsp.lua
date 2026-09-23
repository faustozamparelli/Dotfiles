vim.diagnostic.config({
    severity_sort = true,
    signs = { severity = vim.diagnostic.severity.ERROR },
    underline = { severity = vim.diagnostic.severity.ERROR },
    virtual_text = {
        severity = vim.diagnostic.severity.ERROR,
        spacing = 2,
        source = 'if_many',
    },
    float = { severity = vim.diagnostic.severity.ERROR },
})

vim.lsp.config('pyright', {
    cmd = { 'pyright-langserver', '--stdio' },
    filetypes = { 'python' },
    root_markers = { 'pyproject.toml', 'uv.lock', 'setup.py', 'setup.cfg', 'requirements.txt', '.git' },
    settings = {
        python = {
            analysis = {
                autoImportCompletions = true,
                typeCheckingMode = 'basic',
            },
        },
    },
})

vim.lsp.config('ruff', {
    cmd = { 'ruff', 'server' },
    filetypes = { 'python' },
    root_markers = { 'pyproject.toml', 'uv.lock', 'ruff.toml', '.ruff.toml', '.git' },
})

local toolchain_bin = vim.fs.joinpath(vim.env.HOME, '.local', 'toolchains', 'bin')

vim.lsp.config('clangd', {
    cmd = {
        '/usr/bin/clangd',
        '--background-index',
        '--clang-tidy',
        '--query-driver=' .. toolchain_bin .. '/gcc,' .. toolchain_bin .. '/g++',
    },
    filetypes = { 'c', 'cpp', 'objc', 'objcpp', 'cuda' },
    root_markers = { 'compile_commands.json', 'compile_flags.txt', '.clangd', '.git' },
})

vim.lsp.config('lua_ls', {
    cmd = { 'lua-language-server' },
    filetypes = { 'lua' },
    root_markers = { '.luarc.json', '.luarc.jsonc', '.git' },
    settings = {
        Lua = {
            diagnostics = { globals = { 'vim' } },
            telemetry = { enable = false },
            workspace = { checkThirdParty = false },
        },
    },
})

vim.lsp.config('vtsls', {
    cmd = { 'vtsls', '--stdio' },
    filetypes = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact' },
    root_markers = { 'tsconfig.json', 'jsconfig.json', 'package.json', '.git' },
})

for _, server in ipairs({ 'pyright', 'ruff', 'clangd', 'lua_ls', 'vtsls' }) do
    vim.lsp.enable(server)
end

vim.api.nvim_create_autocmd('LspAttach', {
    desc = 'Enable native LSP completion',
    callback = function(args)
        local client = assert(vim.lsp.get_client_by_id(args.data.client_id))
        if client:supports_method('textDocument/completion') then
            vim.lsp.completion.enable(true, client.id, args.buf, { autotrigger = true })
        end
    end,
})
