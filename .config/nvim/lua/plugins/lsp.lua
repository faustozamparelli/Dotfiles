return {
    {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
        config = function()
            local configs = require("nvim-treesitter.configs")

            configs.setup({
                ensure_installed = {
                    "lua",
                    "json",
                    "vimdoc",
                    "javascript",
                    "typescript",
                    "python",
                    "rust",
                    "cpp",
                    "go",
                    -- "java",
                    "bash",
                    "fish",
                    "markdown",
                    "html",
                    -- "r",
                    -- "rnoweb",
                },
                sync_install = false,
                auto_install = false,
                highlight = {
                    enable = true,
                    additional_vim_regex_highlighting = false,
                },
                indent = {
                    enable = true,
                },
            })
        end,
    },
    {
        'folke/neodev.nvim',
        event = 'VeryLazy',
        dependencies = {
            'neovim/nvim-lspconfig',
        },
        ft = { 'lua' },
        config = true,
    },
    {
        'junnplus/lsp-setup.nvim',
        dependencies = {
            'neovim/nvim-lspconfig',
            'williamboman/mason.nvim',
            'williamboman/mason-lspconfig.nvim',
            'folke/neodev.nvim'
        },
        init = function()
            vim.lsp.set_log_level('debug')
            require('vim.lsp.log').set_format_func(vim.inspect)

            local rounded = { border = 'rounded' }
            vim.diagnostic.config({ float = rounded, underline = false, virtual_text = false })
            local with_rounded = function(handler)
                return vim.lsp.with(handler, rounded)
            end
            vim.lsp.handlers['textDocument/hover'] = with_rounded(vim.lsp.handlers.hover)
            vim.lsp.handlers['textDocument/signatureHelp'] = with_rounded(vim.lsp.handlers.signature_help)
        end,
        opts = {
            mappings = {
                gd = function() require('telescope.builtin').lsp_definitions() end,
                gi = function() require('telescope.builtin').lsp_implementations() end,
                gr = function() require('telescope.builtin').lsp_references() end,
                -- ['<space>f'] = vim.lsp.buf.format,
            },
            inlay_hints = {
                enabled = true,
                debug = true,
            },
            servers = {
                eslint = {},
                pylsp = {
                    settings = {
                        pylsp = {
                            configurationSources = { 'flake8' },
                            plugins = {
                                pycodestyle = {
                                    enabled = false,
                                },
                                mccabe = {
                                    enabled = false,
                                },
                                pyflakes = {
                                    enabled = false,
                                },
                                flake8 = {
                                    enabled = true,
                                },
                                black = {
                                    enabled = true,
                                }
                            }
                        }
                    }
                },
                yamlls = {
                    settings = {
                        yaml = {
                            keyOrdering = false
                        }
                    }
                },
                zk = {},
                jsonls = {},
                bashls = {},
                tsserver = {
                    settings = {
                        typescript = {
                            inlayHints = {
                                includeInlayParameterNameHints = 'all',
                                includeInlayParameterNameHintsWhenArgumentMatchesName = false,
                                includeInlayFunctionParameterTypeHints = true,
                                includeInlayVariableTypeHints = true,
                                includeInlayVariableTypeHintsWhenTypeMatchesName = false,
                                includeInlayPropertyDeclarationTypeHints = true,
                                includeInlayFunctionLikeReturnTypeHints = true,
                                includeInlayEnumMemberValueHints = true,
                            }
                        },
                    }
                },
                clojure_lsp = {},
                dockerls = {},
                jsonnet_ls = {},
                helm_ls = {},
                zls = {
                    cmd = { '/Users/jun/Documents/workspace/zls/zig-out/bin/zls', '--enable-debug-log' },
                    settings = {
                        zls = {
                            enable_inlay_hints = true,
                            inlay_hints_show_builtin = true,
                            inlay_hints_exclude_single_argument = true,
                            inlay_hints_hide_redundant_param_names = true,
                            inlay_hints_hide_redundant_param_names_last_token = true,
                        }
                    }
                },
                gopls = {
                    settings = {
                        gopls = {
                            gofumpt = true,
                            -- staticcheck = true,
                            usePlaceholders = true,
                            codelenses = {
                                gc_details = true,
                            },
                            hints = {
                                rangeVariableTypes = true,
                                parameterNames = true,
                                constantValues = true,
                                assignVariableTypes = true,
                                compositeLiteralFields = true,
                                compositeLiteralTypes = true,
                                functionTypeParameters = true,
                            },
                        },
                    },
                },
                bufls = {},
                html = {},
                lua_ls = {
                    settings = {
                        Lua = {
                            workspace = {
                                checkThirdParty = false,
                            },
                            hint = {
                                enable = true,
                                arrayIndex = 'Disable',
                            },
                        }
                    }
                },
                ['rust_analyzer@nightly'] = {
                    settings = {
                        ['rust-analyzer'] = {
                            diagnostics = {
                                disabled = { 'unresolved-proc-macro' },
                            },
                            cargo = {
                                loadOutDirsFromCheck = true,
                            },
                            procMacro = {
                                enable = true,
                            },
                            inlayHints = {
                                closureReturnTypeHints = {
                                    enable = true
                                },
                            },
                            cache = {
                                warmup = false,
                            }
                        },
                    },
                }
            }
        },
    },
    {
        'ray-x/lsp_signature.nvim',
        event = 'VeryLazy',
        config = true,
    },
    {
        'hrsh7th/nvim-cmp',
        event = 'InsertEnter',
        dependencies = {
            'hrsh7th/cmp-vsnip',
            'hrsh7th/cmp-nvim-lsp',
            'hrsh7th/vim-vsnip',
            'hrsh7th/vim-vsnip-integ',
            'hrsh7th/cmp-buffer',
            'onsails/lspkind-nvim',
            'windwp/nvim-autopairs',
            'hrsh7th/cmp-cmdline',
        },
        config = function()
            local cmp = require('cmp')
            local types = require('cmp.types')
            local cmp_autopairs = require('nvim-autopairs.completion.cmp')
            local opts = {
                formatting = {
                    format = function(entry, vim_item)
                        vim_item.kind = require('lspkind').presets.default[vim_item.kind] .. ' ' .. vim_item.kind

                        -- set a name for each source
                        vim_item.menu = ({
                            buffer = '[Buf]',
                            nvim_lsp = '[LSP]',
                            luasnip = '[Snip]',
                            nvim_lua = '[Lua]',
                            latex_symbols = '[Latex]',
                        })[entry.source.name]
                        return vim_item
                    end,
                },
                window = {
                    completion = cmp.config.window.bordered(),
                    documentation = cmp.config.window.bordered(),
                },
                snippet = {
                    expand = function(args)
                        vim.fn['vsnip#anonymous'](args.body)
                    end,
                },
                mapping = cmp.mapping.preset.insert({
                    -- ['<Tab>'] = cmp.mapping.select_next_item({ behavior = types.cmp.SelectBehavior.Select }),
                    -- ['<S-Tab>'] = function(fallback)
                    --     local function input(keys, mode)
                    --         vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, true, true), mode or 'i',
                    --             true)
                    --     end
                    --
                    --     if vim.fn.pumvisible() == 1 then
                    --         input('<C-p>', 'n')
                    --     elseif vim.fn['vsnip#jumpable']() == -1 then
                    --         input('<Plug>(vsnip-jump-prev)')
                    --     else
                    --         fallback()
                    --     end
                    -- end,
                    ['<C-y>'] = cmp.mapping.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = true }),
                    ['<CR>'] = function(fallback)
                        fallback()
                    end,
                    ['<C-e>'] = function(fallback)
                        fallback()
                    end,
                }),
                completion = {
                    completeopt = 'menu,menuone,noselect',
                },
                preselect = types.cmp.PreselectMode.None,
                sources = {
                    { name = 'nvim_lsp' },
                    { name = 'buffer' },
                    { name = 'vsnip' },
                },
            }
            cmp.setup(opts)
            cmp.event:on('confirm_done', cmp_autopairs.on_confirm_done({ map_char = { tex = '' } }))
        end,
    },
    {
        "folke/trouble.nvim",
        opts = {}, -- for default options, refer to the configuration section for custom setup.
        cmd = "Trouble",
        keys = {
            {
                "E",
                "<cmd>Trouble diagnostics toggle<cr>",
                desc = "Diagnostics (Trouble)",
            },
            -- {
            --     "<leader>xX",
            --     "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
            --     desc = "Buffer Diagnostics (Trouble)",
            -- },
            -- {
            --     "<leader>cs",
            --     "<cmd>Trouble symbols toggle focus=false<cr>",
            --     desc = "Symbols (Trouble)",
            -- },
            -- {
            --     "<leader>cl",
            --     "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
            --     desc = "LSP Definitions / references / ... (Trouble)",
            -- },
            -- {
            --     "<leader>xL",
            --     "<cmd>Trouble loclist toggle<cr>",
            --     desc = "Location List (Trouble)",
            -- },
            -- {
            --     "<leader>xQ",
            --     "<cmd>Trouble qflist toggle<cr>",
            --     desc = "Quickfix List (Trouble)",
            -- },
        },
    }
}
