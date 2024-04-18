return {
  "stevearc/oil.nvim",
  opts = {},
  -- Optional dependencies
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    require("oil").setup({
      keymaps = {
        ["."] = "actions.toggle_hidden",
      },
      view_options = {
        show_hidden = true,
      },
    })
  end,
}
