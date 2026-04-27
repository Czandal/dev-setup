return {
    "nvim-telescope/telescope.nvim",

    tag = "v0.2.1",

    dependencies = {
        "nvim-lua/plenary.nvim"
    },

    config = function()
        require('telescope').setup({
            defaults = {
                layout_config = {
                    -- 0 means "always show preview" regardless of terminal width
                    preview_cutoff = 0,

                    -- Optional: adjust the width of the preview window (e.g., 60%)
                    -- horizontal = {
                    --   preview_width = 0.6,
                    -- }
                },
            }
        })

        local builtin = require('telescope.builtin')
        -- general find
        vim.keymap.set('n', '<leader>pf', function()
            builtin.find_files({ hidden = true })
        end)
        -- find next word
        vim.keymap.set('n', '<leader>pws', function()
            local word = vim.fn.expand("<cword>")
            builtin.grep_string({ search = word })
        end)
        vim.keymap.set('n', '<leader>pWs', function()
            local word = vim.fn.expand("<cWORD>")
            builtin.grep_string({ search = word })
        end)
        vim.keymap.set('n', '<leader>ps', function()
            builtin.grep_string({ search = vim.fn.input("Grep > ") })
        end)
        vim.keymap.set('n', '<leader>ph', function()
            builtin.oldfiles({})
        end)
        vim.keymap.set('n', '<leader>vh', builtin.help_tags, {})
    end
}
