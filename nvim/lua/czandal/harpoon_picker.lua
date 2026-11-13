-- Telescope picker over the harpoon list. <C-d> removes the selected mark.
local function open()
    local harpoon = require("harpoon")
    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local conf = require("telescope.config").values
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")

    local entries = {}
    for index, item in ipairs(harpoon:list().items) do
        if item.value then
            table.insert(entries, { value = item.value, index = index })
        end
    end

    pickers.new({}, {
        prompt_title = "Harpoon",
        finder = finders.new_table({
            results = entries,
            entry_maker = function(entry)
                return {
                    value = entry,
                    display = entry.index .. ". " .. entry.value,
                    ordinal = entry.value,
                    path = entry.value,
                }
            end,
        }),
        previewer = conf.file_previewer({}),
        sorter = conf.generic_sorter({}),
        attach_mappings = function(prompt_bufnr, map)
            -- select() restores the saved cursor position
            actions.select_default:replace(function()
                local selection = action_state.get_selected_entry()
                actions.close(prompt_bufnr)
                if selection then
                    harpoon:list():select(selection.value.index)
                end
            end)

            local function delete_mark()
                local selection = action_state.get_selected_entry()
                if not selection then
                    return
                end
                harpoon:list():remove_at(selection.value.index)
                actions.close(prompt_bufnr)
                open()
            end

            map({ "i", "n" }, "<C-d>", delete_mark)
            return true
        end,
    }):find()
end

return open
