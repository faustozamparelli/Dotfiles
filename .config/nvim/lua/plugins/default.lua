return {
-- Copilot: lazy and togglable
  {
    "github/copilot.vim",
    lazy = true,
    cmd = "Copilot",
    config = function()
      local copilot_enabled = false
      vim.g.copilot_enabled = false
      vim.api.nvim_create_user_command("CopilotToggle", function()
        copilot_enabled = not copilot_enabled
        vim.g.copilot_enabled = copilot_enabled
        vim.notify("Copilot " .. (copilot_enabled and "Enabled" or "Disabled"))
      end, {})
      vim.keymap.set("n", "<leader>c", ":CopilotToggle<CR>", { desc = "Toggle Copilot" })
    end,
  },

  -- Theme
  {
    "iagorrr/noctishc.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      vim.cmd([[set termguicolors]])
      vim.cmd([[syntax enable]])
      vim.cmd([[colorscheme noctishc]])
    end,
  },

  -- Oil file explorer with Zoxide jump
  {
    "stevearc/oil.nvim",
    dependencies = {
      { "echasnovski/mini.icons", opts = {} },
    },
    lazy = false, -- Load immediately to ensure it's available for VimEnter autocmd
    keys = { { "'", "<CMD>Oil<CR>", desc = "Open parent directory" } },
    config = function()
      local oil = require("oil")
      oil.setup({
        default_file_explorer = true,
        skip_confirm_for_simple_edits = true,
        cleanup_delay_ms = 1000,
        columns = { "icon" },
        use_default_keymaps = false,
        view_options = { show_hidden = true },
        keymaps = {
          ["<CR>"] = "actions.select",
          ["<C-o>"] = "actions.open_external",
          ["<C-c>"] = "actions.close",
          ["s"] = "actions.change_sort",
          ["z"] = {
            desc = "Jump to directory with zoxide",
            callback = function()
              vim.ui.input({ prompt = "Zoxide query: " }, function(query)
                if query then
                  local result
                  local handle = io.popen("zoxide query " .. vim.fn.shellescape(query))
                  if handle then
                    result = handle:read("*a")
                    handle:close()
                  end
                  if result and result ~= "" then
                    result = result:gsub("\n$", "")
                    vim.cmd("cd " .. vim.fn.fnameescape(result))
                    oil.open(result)
                    collectgarbage("collect") -- clean up
                  else
                    vim.notify("No directory found for: " .. query)
                  end
                end
              end)
            end,
          },
        },
      })
    end,
  },

  -- Commenting
  {
    "numToStr/Comment.nvim",
    keys = { "cm" }, -- Load only when needed
    config = function()
      require("Comment").setup({
        toggler = { line = "cm" },
        opleader = { line = "cm" },
      })
    end,
  },

  -- Leap navigation
  {
    "ggandor/leap.nvim",
    event = "VeryLazy",
    config = function()
      require("leap").add_default_mappings(true)
    end,
  },

  -- LazyGit
  {
    "kdheepak/lazygit.nvim",
    cmd = {
      "LazyGit", "LazyGitConfig", "LazyGitCurrentFile", "LazyGitFilter", "LazyGitFilterCurrentFile",
    },
    keys = {
      { "<leader>lg", "<cmd>LazyGit<cr>", desc = "Open lazy git" },
    },
    dependencies = { "nvim-lua/plenary.nvim" },
  },

  -- Autopairs
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function()
      require("nvim-autopairs").setup({})
    end,
  },

  -- Indent guides
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    event = "BufReadPre",
    config = function()
      require("ibl").setup({ scope = { show_start = false, show_end = false, show_exact_scope = false } })
    end,
  },

  -- Markdown preview
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    ft = { "markdown" },
    build = function() vim.fn["mkdp#util#install"]() end,
    config = function()
      vim.keymap.set("n", "<leader>mp", "<CMD>MarkdownPreviewToggle<CR>", { desc = "Markdown Preview" })
    end,
  },

  -- QuickRun
  {
    "thinca/vim-quickrun",
    keys = {
      { "<leader>r", "<cmd>QuickRun<CR>", desc = "Run QuickRun" },
    },
    config = function()
      vim.g.quickrun_config = {
        cpp = {
          command = "/opt/homebrew/bin/g++-14",
          ["hook/time/enable"] = 1,
          ["hook/time/precision"] = 3,
        },
        python = { command = "python3" },
      }
    end,
  },
}
