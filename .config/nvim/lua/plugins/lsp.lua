return {
  -- LSP setup (optimized, full functionality)
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPost", "BufNewFile" }, -- BufReadPost is faster than BufReadPre
    dependencies = {
      {
        "williamboman/mason.nvim",
        cmd = "Mason",
        build = ":MasonUpdate",
        config = true,
      },
      {
        "williamboman/mason-lspconfig.nvim",
        event = { "BufReadPost", "BufNewFile" },
        config = function()
          require("mason-lspconfig").setup({
            automatic_installation = false, -- Disable for faster startup
            ensure_installed = { "lua_ls", "pyright", "ts_ls" },  -- No clangd here
            handlers = {
              -- Skip auto-setup for clangd to prevent duplicates
              clangd = function() end,  -- No-op: We'll set it up manually
            },
          })
        end,
      },
    },
    config = function()
      local lspconfig = require("lspconfig")
      local on_attach = function(client, bufnr)
        local bufopts = { buffer = bufnr, noremap = true, silent = true }
        vim.keymap.set("n", "gd", vim.lsp.buf.definition, bufopts)
        vim.keymap.set("n", "gk", vim.lsp.buf.hover, bufopts)
        vim.keymap.set("n", "gr", vim.lsp.buf.references, bufopts)
        vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, bufopts)
        vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, bufopts)

        vim.keymap.set("n", "<leader>f", function()
          vim.lsp.buf.format({ async = true })
        end, bufopts)

        vim.keymap.set("n", "M", function()
          local word = vim.fn.expand("<cword>")
          vim.cmd("Man " .. word)
        end, bufopts)
      end

      -- Cache capabilities to avoid repeated calls
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      -- Optimize LSP memory usage
      capabilities.textDocument.completion.completionItem.snippetSupport = false
      capabilities.textDocument.completion.completionItem.resolveSupport = {
        properties = { "documentation", "detail", "additionalTextEdits" }
      }

      -- Setup non-clangd servers
      local servers = { "lua_ls", "pyright", "ts_ls" }  -- Removed clangd from loop
      for _, server in ipairs(servers) do
        lspconfig[server].setup({
          on_attach = on_attach,
          capabilities = capabilities,
          flags = {
            debounce_text_changes = 150,
          },
        })
      end

      -- Manual custom setup for clangd (only this one will run)
      lspconfig.clangd.setup({
        on_attach = on_attach,
        capabilities = capabilities,
        cmd = {
          "clangd",
          "--header-insertion=never",
          "--query-driver=/opt/homebrew/bin/g++-15",
          "--background-index",
          "--clang-tidy",
          "--log=info",
          "--pch-storage=memory",  -- Optimizes header caching
          "--enable-config",  -- Explicitly enable loading config.yaml
        },
        -- Remove init_options with fallbackFlags - let clangd handle file type detection
        filetypes = { "c", "cpp", "objc", "objcpp" },
        root_dir = function(fname)
          local util = require("lspconfig").util
          return util.root_pattern("compile_commands.json", ".clangd", ".git", "Makefile", "CSES")(fname)
            or util.path.dirname(fname)  -- Fallback to file's directory
        end,
        single_file_support = true,
        flags = {
          debounce_text_changes = 150,
        },
      })

      -- Autocommand to stop any default clangd instances that sneak in
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
        callback = function(args)
          local clients = vim.lsp.get_active_clients({ bufnr = args.buf })
          for _, client in ipairs(clients) do
            if client.name == "clangd" and #client.config.cmd == 1 and client.config.cmd[1] == "clangd" then  -- Detect default (no flags)
              vim.lsp.stop_client(client.id)
              vim.notify("Stopped default clangd instance", vim.log.levels.INFO)
            end
          end
        end,
      })
    end
  },

  -- Completion setup
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),
        }),
        sources = {
          { name = "nvim_lsp" },
          { name = "luasnip" },
        },
      })
    end,
  },

  -- Treesitter for syntax highlighting and indentation
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = "VeryLazy", -- Even lazier loading
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = { "lua", "python", "cpp", "typescript", "markdown" },
        highlight = {
          enable = true,
          disable = function(lang, buf)
            -- Disable for large files to save memory
            local max_filesize = 100 * 1024 -- 100 KB
            local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
            if ok and stats and stats.size > max_filesize then
              return true
            end
          end,
        },
        indent = { enable = true },
        -- Disable incremental selection to save memory
        incremental_selection = { enable = false },
      })
    end,
  },

  -- Optional: LSP progress UI
  {
    "j-hui/fidget.nvim",
    tag = "legacy",
    event = "LspAttach",
    config = function()
      require("fidget").setup({})
    end,
  },

  -- Optional: LSP function signature help
  {
    "ray-x/lsp_signature.nvim",
    event = "VeryLazy",
    config = function()
      require("lsp_signature").setup({ bind = true, handler_opts = { border = "rounded" } })
    end,
  },
}
