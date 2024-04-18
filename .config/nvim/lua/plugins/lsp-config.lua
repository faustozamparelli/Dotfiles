return {
  {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup()
    end,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = {
          "lua_ls",
          "rust_analyzer",
          "jdtls",
          "pyright",
          "clangd",
          "biome",
          "sqlls",
          "bashls",
          "zk",
          "r_language_server"
        },
        auto_install = false,
      })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    config = function()
      local capabilities = require("cmp_nvim_lsp").default_capabilities()
      local lspconfig = require("lspconfig")

      lspconfig.lua_ls.setup({
        capabilities = capabilities,
      })
      lspconfig.rust_analyzer.setup({
        capabilities = capabilities,
      })
      lspconfig.jdtls.setup({
        capabilities = capabilities,
      })
      lspconfig.pyright.setup({
        capabilities = capabilities,
      })
      lspconfig.clangd.setup({
        capabilities = capabilities,
      })
      lspconfig.sqlls.setup({
        capabilities = capabilities,
      })
      lspconfig.biome.setup({
        capabilities = capabilities,
      })
      lspconfig.bashls.setup({
        capabilities = capabilities,
      })
      lspconfig.zk.setup({
        capabilities = capabilities,
      })
      lspconfig.r_language_server .setup({
        capabilities = capabilities,
      })
      vim.keymap.set("n", "<leader>d", vim.lsp.buf.hover, {})
      vim.keymap.set("n", "<leader>gd", vim.lsp.buf.definition, {})
      vim.keymap.set("n", "<leader>td", function()
        local current = vim.diagnostic.config().virtual_text
        vim.diagnostic.config({ virtual_text = not current })
      end, { noremap = true, silent = true })
      vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, {})
    end,
  },
}
