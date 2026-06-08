return {
    "nvim-treesitter/nvim-treesitter",
    -- The new rewrite lives on the `main` branch (required for Neovim 0.11+/0.12).
    -- Pin it here so it stays in sync with the dependency declared in go.lua.
    branch = "main",
    -- Load eagerly so the FileType autocmd below is registered before the
    -- first buffer's filetype is set.
    lazy = false,
    build = ":TSUpdate",
    config = function()
        -- On the `main` branch there is no `configs.setup()` anymore. Parsers and
        -- queries are installed into stdpath("data")/site (already on the rtp),
        -- and highlighting must be started manually per buffer.
        local treesitter = require("nvim-treesitter")

        local ensure_installed = {
            "go", "gomod", "gosum", "gowork", "gotmpl",
            "vimdoc", "javascript", "typescript", "tsx", "c", "lua", "rust",
            "jsdoc", "bash", "markdown", "markdown_inline",
        }

        -- Install any missing parsers (async, no-op for already installed ones).
        treesitter.install(ensure_installed)

        -- Register the `templ` filetype and parser mapping.
        vim.filetype.add({ extension = { templ = "templ" } })
        vim.treesitter.language.register("templ", "templ")

        -- Start treesitter highlighting (and treesitter-based folding) for every
        -- buffer whose filetype has a parser available. This is what gives Go
        -- proper identifier highlighting (function names -> @function, calls ->
        -- @function.call, methods -> @function.method, etc.).
        vim.api.nvim_create_autocmd("FileType", {
            group = vim.api.nvim_create_augroup("czandal_treesitter", { clear = true }),
            callback = function(args)
                local buf = args.buf
                local ft = vim.bo[buf].filetype
                local lang = vim.treesitter.language.get_lang(ft) or ft

                -- pcall: silently skip filetypes without an installed parser.
                if pcall(vim.treesitter.start, buf, lang) then
                    vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
                end
            end,
        })
    end,
}
