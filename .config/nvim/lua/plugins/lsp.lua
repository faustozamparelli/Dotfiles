-- return {
--   {
--     "nvim-treesitter/nvim-treesitter",
--     build = ":TSUpdate",
--     config = function()
--       local configs = require("nvim-treesitter.configs")
--
--       configs.setup({
--         ensure_installed = {
--           "lua",
--           "json",
--           "vimdoc",
--           "javascript",
--           "typescript",
--           "python",
--           "rust",
--           "cpp",
--           "go",
--           -- "java",
--           "bash",
--           "fish",
--           "css",
--           "markdown",
--           "html",
--           -- "r",
--           -- "rnoweb",
--         },
--         sync_install = false,
--         auto_install = false,
--         highlight = {
--           enable = true,
--           additional_vim_regex_highlighting = false,
--         },
--         indent = {
--           enable = true,
--         },
--       })
--     end,
--   },
--   {
--     'folke/neodev.nvim',
--     event = 'VeryLazy',
--     dependencies = {
--       'neovim/nvim-lspconfig',
--     },
--     ft = { 'lua' },
--     config = true,
--   },
--   {
--     'junnplus/lsp-setup.nvim',
--     dependencies = {
--       'neovim/nvim-lspconfig',
--       'williamboman/mason.nvim',
--       'williamboman/mason-lspconfig.nvim',
--       'folke/neodev.nvim'
--     },
--     init = function()
--       vim.lsp.set_log_level('debug')
--       require('vim.lsp.log').set_format_func(vim.inspect)
--
--       local rounded = { border = 'rounded' }
--       vim.diagnostic.config({ float = rounded, underline = false, virtual_text = false })
--       local with_rounded = function(handler)
--         return vim.lsp.with(handler, rounded)
--       end
--       vim.lsp.handlers['textDocument/hover'] = with_rounded(vim.lsp.handlers.hover)
--       vim.lsp.handlers['textDocument/signatureHelp'] = with_rounded(vim.lsp.handlers.signature_help)
--     end,
--     opts = {
--       mappings = {
--         gd = function() require('telescope.builtin').lsp_definitions() end,
--         gi = function() require('telescope.builtin').lsp_implementations() end,
--         gr = function() require('telescope.builtin').lsp_references() end,
--         -- ['<space>f'] = vim.lsp.buf.format,
--       },
--       inlay_hints = {
--         enabled = true,
--         debug = true,
--       },
--       servers = {
--         eslint = {},
--         pylsp = {
--           settings = {
--             pylsp = {
--               configurationSources = { 'flake8' },
--               plugins = {
--                 pycodestyle = {
--                   enabled = false,
--                 },
--                 mccabe = {
--                   enabled = false,
--                 },
--                 pyflakes = {
--                   enabled = false,
--                 },
--                 flake8 = {
--                   enabled = true,
--                 },
--                 black = {
--                   enabled = true,
--                 }
--               }
--             }
--           }
--         },
--         yamlls = {
--           settings = {
--             yaml = {
--               keyOrdering = false
--             }
--           }
--         },
--         zk = {},
--         jsonls = {},
--         bashls = {},
--         tsserver = {
--           settings = {
--             typescript = {
--               inlayHints = {
--                 includeInlayParameterNameHints = 'all',
--                 includeInlayParameterNameHintsWhenArgumentMatchesName = false,
--                 includeInlayFunctionParameterTypeHints = true,
--                 includeInlayVariableTypeHints = true,
--                 includeInlayVariableTypeHintsWhenTypeMatchesName = false,
--                 includeInlayPropertyDeclarationTypeHints = true,
--                 includeInlayFunctionLikeReturnTypeHints = true,
--                 includeInlayEnumMemberValueHints = true,
--               }
--             },
--           }
--         },
--         clojure_lsp = {},
--         dockerls = {},
--         jsonnet_ls = {},
--         helm_ls = {},
--         zls = {
--           cmd = { '/Users/jun/Documents/workspace/zls/zig-out/bin/zls', '--enable-debug-log' },
--           settings = {
--             zls = {
--               enable_inlay_hints = true,
--               inlay_hints_show_builtin = true,
--               inlay_hints_exclude_single_argument = true,
--               inlay_hints_hide_redundant_param_names = true,
--               inlay_hints_hide_redundant_param_names_last_token = true,
--             }
--           }
--         },
--         gopls = {
--           settings = {
--             gopls = {
--               gofumpt = true,
--               -- staticcheck = true,
--               usePlaceholders = true,
--               codelenses = {
--                 gc_details = true,
--               },
--               hints = {
--                 rangeVariableTypes = true,
--                 parameterNames = true,
--                 constantValues = true,
--                 assignVariableTypes = true,
--                 compositeLiteralFields = true,
--                 compositeLiteralTypes = true,
--                 functionTypeParameters = true,
--               },
--             },
--           },
--         },
--         bufls = {},
--         html = {},
--         lua_ls = {
--           settings = {
--             Lua = {
--               workspace = {
--                 checkThirdParty = false,
--               },
--               hint = {
--                 enable = true,
--                 arrayIndex = 'Disable',
--               },
--             }
--           }
--         },
--         ['rust_analyzer@nightly'] = {
--           settings = {
--             ['rust-analyzer'] = {
--               diagnostics = {
--                 disabled = { 'unresolved-proc-macro' },
--               },
--               cargo = {
--                 loadOutDirsFromCheck = true,
--               },
--               procMacro = {
--                 enable = true,
--               },
--               inlayHints = {
--                 closureReturnTypeHints = {
--                   enable = true
--                 },
--               },
--               cache = {
--                 warmup = false,
--               }
--             },
--           },
--         }
--       }
--     },
--   },
--   {
--     'ray-x/lsp_signature.nvim',
--     event = 'VeryLazy',
--     config = true,
--   },
--   {
--     'hrsh7th/nvim-cmp',
--     event = 'InsertEnter',
--     dependencies = {
--       'hrsh7th/cmp-vsnip',
--       'hrsh7th/cmp-nvim-lsp',
--       'hrsh7th/vim-vsnip',
--       'hrsh7th/vim-vsnip-integ',
--       'hrsh7th/cmp-buffer',
--       'onsails/lspkind-nvim',
--       'windwp/nvim-autopairs',
--       'hrsh7th/cmp-cmdline',
--     },
--     config = function()
--       local cmp = require('cmp')
--       local types = require('cmp.types')
--       local cmp_autopairs = require('nvim-autopairs.completion.cmp')
--       local opts = {
--         formatting = {
--           format = function(entry, vim_item)
--             vim_item.kind = require('lspkind').presets.default[vim_item.kind] .. ' ' .. vim_item.kind
--
--             -- set a name for each source
--             vim_item.menu = ({
--               buffer = '[Buf]',
--               nvim_lsp = '[LSP]',
--               luasnip = '[Snip]',
--               nvim_lua = '[Lua]',
--               latex_symbols = '[Latex]',
--             })[entry.source.name]
--             return vim_item
--           end,
--         },
--         window = {
--           completion = cmp.config.window.bordered(),
--           documentation = cmp.config.window.bordered(),
--         },
--         snippet = {
--           expand = function(args)
--             vim.fn['vsnip#anonymous'](args.body)
--           end,
--         },
--         mapping = cmp.mapping.preset.insert({
--           -- ['<Tab>'] = cmp.mapping.select_next_item({ behavior = types.cmp.SelectBehavior.Select }),
--           -- ['<S-Tab>'] = function(fallback)
--           --     local function input(keys, mode)
--           --         vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, true, true), mode or 'i',
--           --             true)
--           --     end
--           --
--           --     if vim.fn.pumvisible() == 1 then
--           --         input('<C-p>', 'n')
--           --     elseif vim.fn['vsnip#jumpable']() == -1 then
--           --         input('<Plug>(vsnip-jump-prev)')
--           --     else
--           --         fallback()
--           --     end
--           -- end,
--           ['<C-y>'] = cmp.mapping.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = true }),
--           ['<CR>'] = function(fallback)
--             fallback()
--           end,
--           ['<C-e>'] = function(fallback)
--             fallback()
--           end,
--         }),
--         completion = {
--           completeopt = 'menu,menuone,noselect',
--         },
--         preselect = types.cmp.PreselectMode.None,
--         sources = {
--           { name = 'nvim_lsp' },
--           { name = 'buffer' },
--           { name = 'vsnip' },
--         },
--       }
--       cmp.setup(opts)
--       cmp.event:on('confirm_done', cmp_autopairs.on_confirm_done({ map_char = { tex = '' } }))
--     end,
--   },
--   {
--     "folke/trouble.nvim",
--     opts = {}, -- for default options, refer to the configuration section for custom setup.
--     cmd = "Trouble",
--     keys = {
--       {
--         "E",
--         "<cmd>Trouble diagnostics toggle<cr>",
--         desc = "Diagnostics (Trouble)",
--       },
--       -- {
--       --     "<leader>xX",
--       --     "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
--       --     desc = "Buffer Diagnostics (Trouble)",
--       -- },
--       -- {
--       --     "<leader>cs",
--       --     "<cmd>Trouble symbols toggle focus=false<cr>",
--       --     desc = "Symbols (Trouble)",
--       -- },
--       -- {
--       --     "<leader>cl",
--       --     "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
--       --     desc = "LSP Definitions / references / ... (Trouble)",
--       -- },
--       -- {
--       --     "<leader>xL",
--       --     "<cmd>Trouble loclist toggle<cr>",
--       --     desc = "Location List (Trouble)",
--       -- },
--       -- {
--       --     "<leader>xQ",
--       --     "<cmd>Trouble qflist toggle<cr>",
--       --     desc = "Quickfix List (Trouble)",
--       -- },
--     }
--   },
--   {
--     'windwp/nvim-ts-autotag',
--     config = function()
--       require('nvim-ts-autotag').setup({
--         opts = {
--           -- Defaults
--           enable_close = true,          -- Auto close tags
--           enable_rename = true,         -- Auto rename pairs of tags
--           enable_close_on_slash = false -- Auto close on trailing </
--         },
--       })
--     end,
--   },
-- }
--
return {
  "VonHeikemen/lsp-zero.nvim",
  branch = "v2.x",
  dependencies = {
    -- LSP Support
    { "neovim/nvim-lspconfig" }, -- Required
    { -- Optional
      "williamboman/mason.nvim",
      build = function()
        pcall(vim.cmd, "MasonUpdate")
      end,
    },
    { "williamboman/mason-lspconfig.nvim" }, -- Optional

    -- Autocompletion
    { "hrsh7th/nvim-cmp" }, -- Required
    { "hrsh7th/cmp-nvim-lsp" }, -- Required
    { "L3MON4D3/LuaSnip" }, -- Required
    { "rafamadriz/friendly-snippets" },
    { "hrsh7th/cmp-buffer" },
    { "hrsh7th/cmp-path" },
    { "hrsh7th/cmp-cmdline" },
    { "saadparwaiz1/cmp_luasnip" },
  },
  config = function()
    local lsp = require("lsp-zero")

    lsp.on_attach(function(client, bufnr)
      local opts = { buffer = bufnr, remap = false }

      vim.keymap.set("n", "gr", function() vim.lsp.buf.references() end, vim.tbl_deep_extend("force", opts, { desc = "LSP Goto Reference" }))
      vim.keymap.set("n", "gd", function() vim.lsp.buf.definition() end, vim.tbl_deep_extend("force", opts, { desc = "LSP Goto Definition" }))
      vim.keymap.set("n", "K", function() vim.lsp.buf.hover() end, vim.tbl_deep_extend("force", opts, { desc = "LSP Hover" }))
      vim.keymap.set("n", "<leader>vws", function() vim.lsp.buf.workspace_symbol() end, vim.tbl_deep_extend("force", opts, { desc = "LSP Workspace Symbol" }))
      vim.keymap.set("n", "<leader>vd", function() vim.diagnostic.setloclist() end, vim.tbl_deep_extend("force", opts, { desc = "LSP Show Diagnostics" }))
      vim.keymap.set("n", "[d", function() vim.diagnostic.goto_next() end, vim.tbl_deep_extend("force", opts, { desc = "Next Diagnostic" }))
      vim.keymap.set("n", "]d", function() vim.diagnostic.goto_prev() end, vim.tbl_deep_extend("force", opts, { desc = "Previous Diagnostic" }))
      vim.keymap.set("n", "<leader>vca", function() vim.lsp.buf.code_action() end, vim.tbl_deep_extend("force", opts, { desc = "LSP Code Action" }))
      vim.keymap.set("n", "<leader>vrr", function() vim.lsp.buf.references() end, vim.tbl_deep_extend("force", opts, { desc = "LSP References" }))
      vim.keymap.set("n", "<leader>vrn", function() vim.lsp.buf.rename() end, vim.tbl_deep_extend("force", opts, { desc = "LSP Rename" }))
      vim.keymap.set("i", "<C-h>", function() vim.lsp.buf.signature_help() end, vim.tbl_deep_extend("force", opts, { desc = "LSP Signature Help" }))
    end)

    require("mason").setup({})
    require("mason-lspconfig").setup({
      ensure_installed = {
        "tsserver",
        "eslint",
        "rust_analyzer",
        "kotlin_language_server",
        "jdtls",
        "lua_ls",
        "jsonls",
        "html",
        "elixirls",
        "tailwindcss",
        "tflint",
        "pylsp",
        "dockerls",
        "bashls",
        "marksman",
        "cucumber_language_server",
        "gopls",
        "astro",
      },
      handlers = {
        lsp.default_setup,
        lua_ls = function()
          local lua_opts = lsp.nvim_lua_ls()
          require("lspconfig").lua_ls.setup(lua_opts)
        end,
      },
    })

    local cmp_action = require("lsp-zero").cmp_action()
    local cmp = require("cmp")
    local cmp_select = { behavior = cmp.SelectBehavior.Select }

    require("luasnip.loaders.from_vscode").lazy_load()

    -- `/` cmdline setup.
    cmp.setup.cmdline("/", {
      mapping = cmp.mapping.preset.cmdline(),
      sources = {
        { name = "buffer" },
      },
    })

    -- `:` cmdline setup.
    cmp.setup.cmdline(":", {
      mapping = cmp.mapping.preset.cmdline(),
      sources = cmp.config.sources({
        { name = "path" },
      }, {
        {
          name = "cmdline",
          option = {
            ignore_cmds = { "Man", "!" },
          },
        },
      }),
    })

    cmp.setup({
      snippet = {
        expand = function(args)
          require("luasnip").lsp_expand(args.body)
        end,
      },
      sources = {
        { name = "nvim_lsp" },
        { name = "luasnip", keyword_length = 2 },
        { name = "buffer", keyword_length = 3 },
        { name = "path" },
      },
      mapping = cmp.mapping.preset.insert({
        ["<C-p>"] = cmp.mapping.select_prev_item(cmp_select),
        ["<C-n>"] = cmp.mapping.select_next_item(cmp_select),
        ["<CR>"] = cmp.mapping.confirm({ select = true }),
        ["<C-Space>"] = cmp.mapping.complete(),
        ["<C-f>"] = cmp_action.luasnip_jump_forward(),
        ["<C-b>"] = cmp_action.luasnip_jump_backward(),
        ["<Tab>"] = cmp_action.luasnip_supertab(),
        ["<S-Tab>"] = cmp_action.luasnip_shift_supertab(),
      }),
    })
  end,
}
