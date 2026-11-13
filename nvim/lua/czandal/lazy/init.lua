return {
    {
        "lewis6991/gitsigns.nvim",
        opts = {
            current_line_blame = true,
        },
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
