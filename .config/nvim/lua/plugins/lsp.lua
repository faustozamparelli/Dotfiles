return {
    -- Mason: LSP server, Linter, and Formatter manager
    {
        "williamboman/mason.nvim",
        config = function()
            require("mason").setup()
        end,
    },

    -- Use mason-tool-installer.nvim to ensure external tools are installed
    {
        "WhoIsSethDaniel/mason-tool-installer.nvim",
        config = function()
            require("mason-tool-installer").setup {
                ensure_installed = {
                    "prettierd",  -- JS/TS/HTML/CSS formatter
                    "black",      -- Python formatter
                    "shfmt",      -- Bash/Zsh formatter
                    "gofumpt",    -- Go formatter
                    "eslint_d",   -- JS/TS linter
                    "stylua",     -- Lua formatter
                },
                auto_update = false,
                run_on_start = true,
            }
        end,
    },

    -- Mason LSP Config
    {
        "williamboman/mason-lspconfig.nvim",
        dependencies = { "williamboman/mason.nvim" },
        config = function()
            require("mason-lspconfig").setup({
                ensure_installed = {
                    "pyright",    -- Python
                    "ts_ls",   -- TypeScript and JavaScript (Fixed name)
                    "gopls",      -- Go
                    "clangd",     -- C, C++
                    "html",       -- HTML
                    "cssls",      -- CSS
                    "bashls",     -- Bash/Zsh LSP
                },
            })
        end,
    },

    -- LSP Configuration
    {
        "neovim/nvim-lspconfig",
        dependencies = { "williamboman/mason-lspconfig.nvim" },
        config = function()
            local lspconfig = require("lspconfig")
            local capabilities = require("cmp_nvim_lsp").default_capabilities()

            local on_attach = function(_, bufnr)
              local bufopts = { noremap = true, silent = true, buffer = bufnr }
              local builtin = require("telescope.builtin") -- Add this line

              vim.keymap.set("n", "gd", vim.lsp.buf.definition, bufopts)
              vim.keymap.set("n", "gr", builtin.lsp_references, bufopts) -- Use Telescope here
              vim.keymap.set("n", "gD", vim.lsp.buf.declaration, bufopts)
              vim.keymap.set("n", "gT", vim.lsp.buf.type_definition, bufopts)
              vim.keymap.set("n", "K", vim.lsp.buf.hover, bufopts)
              vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, bufopts)
              vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, bufopts)
              vim.keymap.set("n", "<leader>f", function() vim.lsp.buf.format({ async = true }) end, bufopts)
                -- Auto-format on save
                vim.api.nvim_create_autocmd("BufWritePre", {
                    buffer = bufnr,
                    callback = function()
                        vim.lsp.buf.format({ async = false })
                    end,
                })
            end

            -- Setup each server
            local servers = { "pyright", "ts_ls", "gopls", "clangd", "html", "cssls", "bashls" }
            for _, server in ipairs(servers) do
                lspconfig[server].setup({
                    capabilities = capabilities,
                    on_attach = on_attach,
                })
            end
        end,
    },

    -- Auto-completion
    {
        "hrsh7th/nvim-cmp",
        dependencies = {
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/cmp-buffer",
            "hrsh7th/cmp-path",
            "saadparwaiz1/cmp_luasnip",
        },
        config = function()
            local cmp = require("cmp")
            cmp.setup({
                snippet = {
                    expand = function(args)
                        require("luasnip").lsp_expand(args.body)
                    end,
                },
                mapping = {
                    ["<S-Tab>"] = cmp.mapping.select_prev_item(),
                    ["<Tab>"] = cmp.mapping.select_next_item(),
                    ["<C-Space>"] = cmp.mapping.complete(),
                    ["<C-y>"] = cmp.mapping.confirm({ select = true }),
                },
                sources = {
                    { name = "nvim_lsp" },
                    { name = "buffer" },
                    { name = "path" },
                },
            })
        end,
    },

    -- Null-LS for linting and formatting
    {
        "jose-elias-alvarez/null-ls.nvim",
        dependencies = { "nvim-lua/plenary.nvim" },
        config = function()
            local null_ls = require("null-ls")
            null_ls.setup({
                sources = {
                    null_ls.builtins.formatting.black,    -- Python formatter
                    null_ls.builtins.formatting.prettierd, -- JS/TS/HTML/CSS formatter
                    null_ls.builtins.formatting.gofumpt,  -- Go formatter
                    null_ls.builtins.formatting.shfmt,    -- Shell script formatter
                    null_ls.builtins.formatting.stylua,   -- Lua formatter
                    null_ls.builtins.diagnostics.eslint,  -- JS/TS linter
                },
            })
        end,
    },

    -- Snippets
    {
        "L3MON4D3/LuaSnip",
        config = function()
            require("luasnip.loaders.from_vscode").lazy_load()
        end,
    },
}
