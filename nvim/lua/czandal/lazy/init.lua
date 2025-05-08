return {
    {
        "nvim-lua/plenary.nvim",
        name = "plenary",
    },
    rocks = {
        enabled = false,
        hererocks = false,
    },
    {
        "APZelos/blamer.nvim",
        name = "blamer"
    },
    {
        "sbdchd/neoformat",
        name = "neoformat"
    },
    {
        "folke/lazydev.nvim",
        ft = "lua", -- only load on lua files
        opts = {
            library = {
                { path = "${3rd}/luv/library", words = { "vim%.uv" } },
            },
        },
    },
}

