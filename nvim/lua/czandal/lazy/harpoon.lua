return {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-telescope/telescope.nvim",
    },
    config = function()
        local harpoon = require("harpoon")
        local pickers = require("telescope.pickers")
        local finders = require("telescope.finders")
        local conf = require("telescope.config").values
        local actions = require("telescope.actions")
        local action_state = require("telescope.actions.state")

        harpoon:setup({})

        local function toggle_telescope(harpoon_files)
            local file_paths = {}
            for _, item in ipairs(harpoon_files.items) do
                if item.value then
                    table.insert(file_paths, item.value)
                end
            end

            pickers.new({}, {
                prompt_title = "Harpoon",
                finder = finders.new_table({
                    results = file_paths,
                }),
                previewer = conf.file_previewer({}),
                sorter = conf.generic_sorter({}),
                attach_mappings = function(prompt_bufnr, map)
                    actions.select_default:replace(function()
                        local selection = action_state.get_selected_entry()
                        actions.close(prompt_bufnr)
                        if selection and selection[1] then
                            vim.cmd.edit(selection[1])
                        end
                    end)

                    map("i", "<C-d>", function()
                        local selection = action_state.get_selected_entry()
                        if not selection or not selection[1] then
                            return
                        end

                        for idx, item in ipairs(harpoon:list().items) do
                            if item.value == selection[1] then
                                harpoon:list():remove_at(idx)
                                break
                            end
                        end

                        actions.close(prompt_bufnr)
                        toggle_telescope(harpoon:list())
                    end)

                    map("n", "<C-d>", function()
                        local selection = action_state.get_selected_entry()
                        if not selection or not selection[1] then
                            return
                        end

                        for idx, item in ipairs(harpoon:list().items) do
                            if item.value == selection[1] then
                                harpoon:list():remove_at(idx)
                                break
                            end
                        end

                        actions.close(prompt_bufnr)
                        toggle_telescope(harpoon:list())
                    end)

                    return true
                end,
            }):find()
        end

        vim.keymap.set("n", "<leader>a", function()
            harpoon:list():append()
        end, { desc = "Harpoon add file" })

        vim.keymap.set("n", "<C-e>", function()
            toggle_telescope(harpoon:list())
        end, { desc = "Harpoon telescope menu" })

        vim.keymap.set("n", "<C-h>", function()
            harpoon:list():select(1)
        end, { desc = "Harpoon file 1" })

        vim.keymap.set("n", "<C-t>", function()
            harpoon:list():select(2)
        end, { desc = "Harpoon file 2" })

        vim.keymap.set("n", "<C-n>", function()
            harpoon:list():select(3)
        end, { desc = "Harpoon file 3" })

        vim.keymap.set("n", "<C-s>", function()
            harpoon:list():select(4)
        end, { desc = "Harpoon file 4" })
    end,
}
