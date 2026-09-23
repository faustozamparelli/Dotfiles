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

local function python_environment(_, config)
    local root = config.root_dir or vim.fn.getcwd()
    local project_python = vim.fs.joinpath(root, '.venv', 'bin', 'python')

    config.settings = config.settings or {}
    config.settings.python = config.settings.python or {}
    config.settings.python.analysis = config.settings.python.analysis or {}

    if vim.fn.executable(project_python) == 1 then
        config.settings.python.pythonPath = project_python
        return
    end

    if vim.env.VIRTUAL_ENV then
        local active_python = vim.fs.joinpath(vim.env.VIRTUAL_ENV, 'bin', 'python')
        if vim.fn.executable(active_python) == 1 then
            config.settings.python.pythonPath = active_python
            return
        end
    end

    local python = vim.fn.exepath('python3')
    if python ~= '' then
        config.settings.python.pythonPath = python
    end

    -- Most Homebrew Python libraries are linked into the main interpreter's
    -- site-packages. Formulae such as pytorch are intentionally isolated in
    -- libexec, so expose those stubs/sources to Pyright only when no project
    -- virtual environment is active.
    local extra_paths = vim.fn.glob('/opt/homebrew/opt/pytorch/libexec/lib/python*/site-packages', true, true)
    if #extra_paths > 0 then
        config.settings.python.analysis.extraPaths = extra_paths
    end
end

vim.lsp.config('pyright', {
    cmd = { 'pyright-langserver', '--stdio' },
    filetypes = { 'python' },
    root_markers = { '.venv', 'pyproject.toml', 'uv.lock', 'setup.py', 'setup.cfg', 'requirements.txt', '.git' },
    before_init = python_environment,
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

vim.lsp.config('clangd', {
    cmd = {
        '/usr/bin/clangd',
        '--background-index',
        '--clang-tidy',
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
