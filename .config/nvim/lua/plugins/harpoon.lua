return {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim", "nvim-telescope/telescope.nvim"},
    config = function()
        local harpoon = require("harpoon")

        -- REQUIRED
        harpoon:setup()
        -- REQUIRED

        vim.keymap.set("n", "<leader>a", function() harpoon:list():add() end)
        vim.keymap.set("n", "<C-e>", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end)

        vim.keymap.set("n", "<S-h>", function() harpoon:list():select(1) end)
        vim.keymap.set("n", "<S-j>", function() harpoon:list():select(2) end)
        vim.keymap.set("n", "<S-k>", function() harpoon:list():select(3) end)
        vim.keymap.set("n", "<S-l>", function() harpoon:list():select(4) end)
    end,
}
