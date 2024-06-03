return {
    { "github/copilot.vim", config = function() end },
    {
        "iagorrr/noctishc.nvim",
        config = function()
            vim.cmd([[set termguicolors]])
            vim.cmd([[syntax enable]])
            vim.cmd([[colorscheme noctishc]])
        end,
    },
    {
        "stevearc/oil.nvim",
        config = function()
            require("oil").setup({
                default_file_explorer = true,
                columns = {
                    "size",
                },
                skip_confirm_for_simple_edits = true,
                cleanup_delay_ms = 1000,
                use_default_keymaps = false,
                keymaps = {
                    ["<CR>"] = "actions.select",
                    ["<C-o>"] = "actions.open_external",
                    ["<C-c>"] = "actions.close",
                    ["s"] = "actions.change_sort",
                },
            })
            vim.keymap.set("n", "'", "<CMD>Oil<CR>", { desc = "Open parent directory" })
        end,
    },
    {
        "numToStr/Comment.nvim",
        opts = {},
        lazy = false,
        config = function()
            require("Comment").setup({
                toggler = {
                    line = "cm",
                },
                opleader = {
                    line = "cm",
                },
            })
        end,
    },
    {
        "ggandor/leap.nvim",
        enabled = true,
        keys = {
            { "s",  mode = { "n", "x", "o" }, desc = "Leap Forward to" },
            { "S",  mode = { "n", "x", "o" }, desc = "Leap Backward to" },
            { "gs", mode = { "n", "x", "o" }, desc = "Leap from Windows" },
        },
        config = function(_, opts)
            local leap = require("leap")
            for k, v in pairs(opts) do
                leap.opts[k] = v
            end
            leap.add_default_mappings(true)
        end,
    },
    {
        "tpope/vim-fugitive",
        config = function()
            vim.keymap.set("n", "<leader>gs", ":Git<CR>", { silent = true })
            vim.keymap.set("n", "<leader>gp", ":Git push<CR>", { silent = true })
            vim.keymap.set("n", "<leader>gl", ":Git pull<CR>", { silent = true })
        end,
    },
    {
        "windwp/nvim-autopairs",
        event = "InsertEnter",
        config = function()
            local npairs = require("nvim-autopairs")
            npairs.setup({})
        end,
    },
    {
        "lukas-reineke/indent-blankline.nvim",
        main = "ibl",
        config = function()
            require("ibl").setup({ scope = { show_start = false, show_end = false, show_exact_scope = false } })
        end
    },
}
