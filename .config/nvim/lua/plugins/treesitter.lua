return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      local configs = require("nvim-treesitter.configs")

      configs.setup({
        ensure_installed = {
          "c",
          "lua",
          "vim",
          "vimdoc",
          "query",
          "typescript",
          "python",
          "rust",
          "cpp",
          "go",
          "java",
          "bash",
          "markdown",
          "markdown_inline",
        },
        sync_install = true,
        auto_install = true,
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = true,
        },
        indent = { enable = true },
        markid = {enable = true}
      })
    end,
  },
}
