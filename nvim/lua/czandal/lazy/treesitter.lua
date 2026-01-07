return {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
        -- 1. OBSOLETE: require("nvim-treesitter.configs").setup(...) is GONE.
        -- Highlighting is now enabled by default in Neovim for installed parsers.

        -- 2. "ensure_installed" is no longer a core feature in the same way.
        -- You can manually install parsers via command: :TSInstall javascript lua c ...
        -- Or use a simple loop to install them if missing:
        local parsers_to_install = {
            "vimdoc", "javascript", "typescript", "c", "lua", "rust",
            "jsdoc", "bash", "markdown"
        }

        -- Optional: Simple auto-installer loop (adaptation for new version)
        -- Note: The API for installation might differ, but :TSInstall <lang> works.
        for _, lang in ipairs(parsers_to_install) do
            if vim.fn.executable("tree-sitter") == 1 then
                -- This is a fallback; usually you just run :TSInstall all manually once.
                vim.cmd("silent! TSInstall " .. lang)
            end
        end

        -- 3. Register 'templ' filetype (Standard Neovim API)
        vim.filetype.add({ extension = { templ = "templ" } })

        -- 4. Register 'templ' parser
        -- The "parser_configs" module is also likely changed/removed.
        -- For custom parsers on 'main', you typically need to install them manually
        -- or wait for upstream support.
        -- However, you can register the language for Neovim:
        vim.treesitter.language.register("templ", "templ")
    end
}

