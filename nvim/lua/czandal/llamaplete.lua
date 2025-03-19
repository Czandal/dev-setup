local StaggeredTask = require('czandal.staggered_task')
local logger = require('czandal.logger')
local utils = require('czandal.utils')
-- TODO: Handle cursor being at the end of buffer
-- TODO: Setup config
-- host
-- enable/disable
-- add commands
-- clean up the files
-- separate extra variables
local plugin_name = "llamaplete"
local llamaplete = {
    namespace = nil,
    hint_id = nil,
    disabled = false,
    llama_host = 'http://127.0.0.1:11434/api/generate',
    raw_hint_output_jsons = '',
    hint_complete = true,
    accumulated_hint = '',
    on_close = nil,
    move_trigger = nil,
    lines_in_context = 10,
    allowed_file_types = {},
    blacklisted_file_types = {}
}

--- @return integer
function llamaplete:get_namespace()
    if not self.namespace then
        self.namespace = vim.api.nvim_create_namespace(plugin_name)
    end
    return self.namespace
end

---@return string[]
function llamaplete:get_current_hint_lines()
    if self.raw_hint_output_jsons ~= nil and #self.raw_hint_output_jsons > 0 then
        local remaining_lines = {}
        local decoded_hint_parts = {}
        for line in self.raw_hint_output_jsons:gmatch("([^\n]*)\n?") do
            -- Ignore lines which do not end with "}" and consider them "incomplete"
            if string.sub(line, -1) == "}" then
                -- TODO: Fix this error, debug why it happens in the first place
                xpcall(function() table.insert(decoded_hint_parts, vim.fn.json_decode(line).response) end, function(err)
                    logger:error({ err, line })
                end)
            else
                table.insert(remaining_lines, line)
            end
        end

        self.raw_hint_output_jsons = table.concat(remaining_lines, "\n")
        self.accumulated_hint = self.accumulated_hint .. table.concat(decoded_hint_parts, '')
    end
    if #self.accumulated_hint > 0 then
        local out = {}
        for line in self.accumulated_hint:gmatch("([^\n]*)\n?") do
            table.insert(out, line)
        end
        if #out > 0 then
            -- remove dangling new line if present
            local last_line = out[#out]
            if string.sub(last_line, -1) == "\n" then
                out[#out] = string.sub(last_line, 0, #last_line - 1)
            end
            -- remove empty line if it is the last one
            last_line = out[#out]
            if last_line == "" then
                table.remove(out)
            end
        end
        if self.hint_complete == false then
            table.insert(out, "(Generating ⏳)")
        end
        return out
    end
    return {}
end


function llamaplete:clear_hint()
    if self.on_close ~= nil then
        self.on_close()
        self.on_close = nil
    end
    if self.hint_id == nil then
        return
    end
    vim.api.nvim_buf_del_extmark(0, self.get_namespace(self), self.hint_id)
    self.hint_id = nil
end

function llamaplete:stop()
    self.disabled = true
    self.clear_hint(self)
end

---@return boolean
function llamaplete:should_run()
    local full_path = vim.api.nvim_buf_get_name(0)
    for filetype in self.blacklisted_file_types do
        if string.find(full_path, filetype) ~= nil then
            return false
        end
    end
    for filetype in self.allowed_file_types do
        if string.find(full_path, filetype) ~= nil then
            return true
        end
    end
    if #self.allowed_file_types < 1 then
        return true
    end
    return false
end

function llamaplete:start()
    if llamaplete:should_run() == false then
        return
    end
    self.disabled = false
    self.clear_hint(self)
    self.on_close = self.request_new_hint(self)
end

function llamaplete:cursor_moved()
    -- stop current generation
    self.clear_hint(self)
    if self.disabled then
        return
    end
    if self.move_trigger and not self.move_trigger.ran then
        self.move_trigger:run_with_stagger(50)
        return
    end
    self.move_trigger = StaggeredTask:new(function()
        self.on_close = self.request_new_hint(self)
    end)
    self.move_trigger:run_with_stagger(50)
end

function llamaplete:update_hint()
    if self.disabled then
        return
    end
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    local hint_lines = self.get_current_hint_lines(self)
    -- nothing to do
    if #hint_lines == 0 then
        return
    elseif #hint_lines == 1 then
        self.hint_id = vim.api.nvim_buf_set_extmark(0, llamaplete:get_namespace(), row - 1, col, {
            id = self.hint_id,
            hl_group = 'Comment',
            virt_text_pos = 'inline',
            hl_eol = false,
            strict = false,
            virt_text = { { hint_lines[1], 'Comment' } },
        })
        return
    end
    local remnant = utils.read_to_end_of_line(0, row - 1, col)
    local start_of_hint = { { hint_lines[1] .. string.rep(' ', #remnant), 'Comment' } }
    local hint_tail = {}
    for i = 2, #hint_lines - 1 do
        table.insert(hint_tail, { { hint_lines[i], 'Comment' } })
    end
    local last_line = hint_lines[#hint_lines]
    table.insert(hint_tail, { { last_line .. remnant, 'Comment' } })
    self.hint_id = vim.api.nvim_buf_set_extmark(0, llamaplete:get_namespace(), row - 1, col, {
        id = self.hint_id,
        hl_group = 'Comment',
        virt_text_pos = 'overlay',
        hl_eol = false,
        strict = false,
        virt_text = start_of_hint,
        virt_lines = hint_tail
    })
end

function llamaplete:accept_hint()
    if self.hint_id == nil then
        return
    end

    local hint_lines = self.get_current_hint_lines(self)
    if #hint_lines == 0 then
        return
    end

    local hint_data =
        vim.api.nvim_buf_get_extmark_by_id(0, self.get_namespace(self), self.hint_id, {})
    local row = hint_data[1]
    local col = hint_data[2]
    -- Add new lines to the buffer
    vim.api.nvim_buf_set_text(0, row, col, row, col, hint_lines)
    -- Move the cursor to the end of the added text
    local row_offset = row + #hint_lines
    local col_offset = col + #hint_lines[1]
    vim.api.nvim_win_set_cursor(0, { row_offset, col_offset })
end

function llamaplete:get_prefix()
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    local start_line = row - self.lines_in_context
    -- No need to check boundary, function does it for us
    local lines = vim.api.nvim_buf_get_lines(0, start_line, row, false)
    if #lines < 1 then
        return ""
    end
    local last_line = table.remove(lines):sub(1, col)
    table.insert(lines, last_line)
    return table.concat(lines, "\n")
end

function llamaplete:get_suffix()
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    local end_line = row + self.lines_in_context
    -- No need to check boundary, function does it for us
    local lines = vim.api.nvim_buf_get_lines(0, row - 1, end_line, false)
    if #lines < 1 then
        return ""
    end
    local first_line = string.sub(lines[1], col + 1)
    lines[1] = first_line
    return table.concat(lines, "\n")
end

function llamaplete:request_new_hint()
    local closed = false
    self.hint_complete = false
    self.raw_hint_output_jsons = ""
    self.accumulated_hint = ''
    local handle
    local update_hint_with_stagger = StaggeredTask:new(function()
        self.update_hint(self)
    end)
    local payload = {
        model = 'deepseek-coder-v2',
        prompt = self.get_prefix(self),
        suffix = self.get_suffix(self),
        max_tokens = 32
    }
    logger:echo("requesting")
    local stdout = vim.uv.new_pipe(false)
    local stderr = vim.uv.new_pipe(false)
    ---@diagnostic disable-next-line: missing-fields
    handle = vim.uv.spawn("curl", {
        hide = true,
        detached = true,
        args = {
            "--silent", "--location", self.llama_host,
            "-X", "POST",
            "--data", vim.fn.json_encode(payload),
            "--header", "Content-Type: application/json"
        }, -- Replace with your URL
        stdio = { nil, stdout, stderr }
    }, function(code, signal)
        if code ~= 0 then
            logger:error({ "Failed to retrieve autosuggestion, process exited", code, signal })
        end
        logger:info("Finished retrieving data from autosuggestion server")
        self.hint_complete = true
        handle:close()
    end)
    if stdout then
        vim.uv.read_start(stdout, function(err, data)
            if self.disabled or closed then
                return
            end
            if err then
                logger:error({"Failure", err})
                return
            end
            if data and #data > 0 then
                self.raw_hint_output_jsons = self.raw_hint_output_jsons .. data
                update_hint_with_stagger:run_with_stagger(15)
            end
        end)
    end
    if stderr then
        vim.uv.read_start(stderr, function(err, data)
            if self.disabled or closed then
                return
            end
            if err then
                logger:error({"Failure", err})
                return
            end
            if data then
                self.raw_hint_output_jsons = self.raw_hint_output_jsons .. data
                update_hint_with_stagger:run_with_stagger(15)
            end
        end)
    end
    return function()
        logger:info("On Close called")
        closed = true
        self.hint_complete = true
        update_hint_with_stagger:stop()
    end
end

--#region Globals

function LlamapleteDebug()
    llamaplete:cursor_moved()
end

function LlamapleteDebug2()
    llamaplete:stop()
end

function LlamapleteStart()
    llamaplete:start()
end

function LlamapleteCursorMoved()
    llamaplete:cursor_moved()
end

function LlamapleteStop()
    llamaplete:stop()
end

function LlamapleteAcceptHint()
    llamaplete:accept_hint()
    llamaplete:clear_hint()
end

function LlamapleteRejectHint()
    llamaplete:clear_hint()
end

function LlamapleteRefreshHint()
    llamaplete:cursor_moved()
end

---@class LllamapleteConfig
---@field register_autocmd? boolean defaults to false
---@field host? string defaults to http://localhost:11434/api/generate
---@field context_line_size? integer defaults to 10
---@field allowed_file_types? string[] if empty starts the llamaplete for all kind of files
---can use patterns, but string.find is used under the hood so one needs to use ".*"
---@field blacklisted_file_types? string[] if empty defaults to empty list
---can use patterns, but string.find is used under the hood so one needs to use ".*" instead of "*" to match any string
---@field default_keymaps? boolean defaults to false

---@param config LllamapleteConfig
function llamaplete.setup(config)
    llamaplete.lines_in_context = config.context_line_size or 10
    llamaplete.llama_host = config.host or "http://localhost:11434/api/generate"
    llamaplete.allowed_file_types = config.allowed_file_types or {}
    llamaplete.blacklisted_file_types = config.blacklisted_file_types or {}
    --#region autocmd
    if config.register_autocmd then
        vim.api.nvim_command('autocmd InsertEnter * lua LlamapleteStart()')
        vim.api.nvim_command('autocmd CursorMovedI * lua LlamapleteCursorMoved()')
        vim.api.nvim_command('autocmd InsertLeave * lua LlamapleteStop()')
    end
    --#endregion autocmd
    --#region register nvim commands
    vim.api.nvim_create_user_command("LllamapleteStart", function()
        LlamapleteStart()
    end, { desc = "Start pulling autosuggestions from LLM server" })
    vim.api.nvim_create_user_command("LlamapleteStop", function ()
        LlamapleteStop()
    end, { desc = "Stop llamaplete" })
    vim.api.nvim_create_user_command("LlamapleteAcceptHint", function()
        LlamapleteAcceptHint()
    end, { desc = "Accept llamaplete complete autosuggestion" })
    vim.api.nvim_create_user_command("LlamapleteRejectHint", function ()
        LlamapleteRejectHint()
    end, { desc = "Reject llamaplete complete autosuggestion" })
    vim.api.nvim_create_user_command("LlamapleteRefreshHint", function ()
        LlamapleteRefreshHint()
    end, { desc = "Refresh llamaplete autosuggestion" })
    --#endregion register nvim commands
    --#region keymaps
    if config.default_keymaps then
        vim.keymap.set("i", "<C-S>", "<CMD>LlamapleteAcceptHint<CR>", { desc = "Accept llamaplete autosuggestion" })
        vim.keymap.set("i", "<C-R>", "<CMD>LllamapleteRejectHint<CR>", { desc = "Reject llamaplete autosuggestion" })
        vim.keymap.set("i", "<C-X>", "<CMD>LllamapleteRefreshHint<CR>", { desc = "Refresh llamaplete autosuggestion" })
    end
    --#endregion keymaps
end
return llamaplete
