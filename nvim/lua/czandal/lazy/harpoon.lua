return {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-telescope/telescope.nvim",
    },
    opts = {
        settings = {
            save_on_toggle = true,
            sync_on_ui_close = true,
        },
    },
    keys = {
        { "<leader>a", function() require("harpoon"):list():add() end,       desc = "Harpoon add file" },
        { "<C-e>",     function() require("czandal.harpoon_picker")() end,   desc = "Harpoon telescope menu" },
        { "<C-h>",     function() require("harpoon"):list():select(1) end,   desc = "Harpoon file 1" },
        { "<C-t>",     function() require("harpoon"):list():select(2) end,   desc = "Harpoon file 2" },
        { "<C-n>",     function() require("harpoon"):list():select(3) end,   desc = "Harpoon file 3" },
        { "<C-s>",     function() require("harpoon"):list():select(4) end,   desc = "Harpoon file 4" },
    },
    config = function(_, opts)
        require("harpoon"):setup(opts)
    end,
}
