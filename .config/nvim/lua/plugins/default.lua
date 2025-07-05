return {
-- Copilot: lazy and togglable
  {
    "github/copilot.vim",
    cmd = "Copilot",
    keys = { 
      { 
        "<leader>c", 
        function()
          -- Load copilot if not already loaded
          if not package.loaded["copilot"] then
            require("lazy").load({ plugins = { "copilot.vim" } })
          end
          
          -- Toggle copilot
          vim.g.copilot_enabled = not vim.g.copilot_enabled
          if vim.g.copilot_enabled then
            vim.cmd("Copilot enable")
            vim.notify("Copilot Enabled")
          else
            vim.cmd("Copilot disable")
            vim.notify("Copilot Disabled")
          end
        end,
        desc = "Toggle Copilot" 
      } 
    },
    config = function()
      vim.g.copilot_enabled = false
    end,
  },

  -- Theme (only non-lazy plugin for immediate UI)
  {
    "iagorrr/noctishc.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      vim.cmd.colorscheme("noctishc")
    end,
  },

  -- Oil file explorer with Zoxide jump
  {
    "stevearc/oil.nvim",
    dependencies = {
      { "echasnovski/mini.icons", opts = {} },
    },
    cmd = "Oil",
    keys = { { "'", "<CMD>Oil<CR>", desc = "Open parent directory" } },
    init = function()
      -- Ensure oil is available for VimEnter autocmd without loading it
      if vim.fn.argc() == 1 and vim.fn.isdirectory(vim.fn.argv(0)) == 1 then
        require("lazy").load({ plugins = { "oil.nvim" } })
      end
    end,
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
    keys = {
      { "cm", mode = "n" },
      { "cm", mode = "v" },
    },
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
      local npairs = require("nvim-autopairs")
      local Rule = require("nvim-autopairs.rule")
      
      npairs.setup({
        check_ts = true,
        ts_config = {
          lua = {'string'},-- it will not add a pair on that treesitter node
          javascript = {'template_string'},
          java = false,-- don't check treesitter on java
        }
      })
      
      -- Multi-line comment rules for various languages
      local comment_rules = {
        -- C/C++/JavaScript/CSS/Java style comments
        Rule("/*", "*/"),
        -- HTML/XML style comments  
        Rule("<!--", "-->"),
        -- Haskell style comments
        Rule("{-", "-}"),
        -- OCaml style comments
        Rule("(*", "*)"),
        -- Lua multi-line comments
        Rule("--[[", "]]"),
        -- Python multi-line strings (docstrings)
        Rule('"""', '"""'),
        -- Markdown code blocks
        Rule("```", "```"),
        -- PowerShell multi-line comments
        Rule("<#", "#>"),
      }
      
      -- Add all the comment rules
      for _, rule in ipairs(comment_rules) do
        npairs.add_rule(rule)
      end
      
      -- Add some language-specific rules with conditions
      npairs.add_rules({
        -- Space after opening comment
        Rule("/* ", " */")
          :with_pair(function() return false end)
          :with_move(function(opts)
            return opts.prev_char:match(".%*/") ~= nil
          end)
          :use_key(" "),
        
        Rule("<!-- ", " -->")
          :with_pair(function() return false end)
          :with_move(function(opts)
            return opts.prev_char:match(".%->") ~= nil
          end)
          :use_key(" "),
          
        Rule("{- ", " -}")
          :with_pair(function() return false end)
          :with_move(function(opts)
            return opts.prev_char:match(".%-}") ~= nil
          end)
          :use_key(" "),
      })
      
      -- Integration with nvim-cmp if available
      local cmp_status_ok, cmp = pcall(require, "cmp")
      if cmp_status_ok then
        local cmp_autopairs = require("nvim-autopairs.completion.cmp")
        cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
      end
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
