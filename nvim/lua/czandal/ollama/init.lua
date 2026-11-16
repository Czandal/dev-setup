-- Local Ollama "skills" run on a visual selection.
--   <leader>b (visual)  pick a skill and run it on the selection
--   :OllamaCancel       cancel running requests
local client = require("czandal.ollama.client")
local review = require("czandal.ollama.review")
local api = vim.api

local M = {}

M.config = {
    host = "http://localhost:11434",
    keymap = "<leader>b",
    timeout = 600000, -- ms; an 11B model on long text can be slow
    skills = {},
}
M.skills = {}

local ns_sel = api.nvim_create_namespace("czandal_ollama_selection")
local SPINNER = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }

local function notify(msg, level)
    vim.notify(msg, level or vim.log.levels.INFO, { title = "ollama" })
end

--- Read the current visual selection (must be called while in visual mode).
local function get_selection()
    local mode = vim.fn.mode()
    if mode == "\22" then
        return nil, "zaznaczenie blokowe nie jest obsługiwane"
    end
    local p1, p2 = vim.fn.getpos("v"), vim.fn.getpos(".")
    local lines = vim.fn.getregion(p1, p2, { type = mode })
    local reg = vim.fn.getregionpos(p1, p2, { type = mode })
    if #lines == 0 or #reg == 0 then
        return nil, "puste zaznaczenie"
    end
    -- charwise selection that includes the final EOL yields a trailing ""
    if #lines > 1 and lines[#lines] == "" then
        table.remove(lines)
    end
    local sr = reg[1][1][2] - 1
    local sc = mode == "V" and 0 or reg[1][1][3] - 1
    local er = sr + #lines - 1
    local ec = (#lines == 1 and sc or 0) + #lines[#lines]
    return {
        buf = api.nvim_get_current_buf(),
        sr = sr, sc = sc, er = er, ec = ec,
        text = table.concat(lines, "\n"),
    }
end

local function start_spinner(buf, mark, skill)
    local timer = vim.uv.new_timer()
    local t0, frame, vid = vim.uv.now(), 0, nil
    timer:start(0, 100, vim.schedule_wrap(function()
        if not api.nvim_buf_is_valid(buf) then return end
        local m = api.nvim_buf_get_extmark_by_id(buf, ns_sel, mark, { details = true })
        if not m or not m[1] then return end
        frame = frame % #SPINNER + 1
        local secs = math.floor((vim.uv.now() - t0) / 1000)
        vid = api.nvim_buf_set_extmark(buf, ns_sel, m[3].end_row or m[1], 0, {
            id = vid,
            virt_text = { { (" %s %s… %ds"):format(SPINNER[frame], skill.name, secs), "Comment" } },
            virt_text_pos = "eol",
        })
    end))
    return function()
        timer:stop()
        timer:close()
    end
end

local handlers = {}

function handlers.review(_, buf, r1, c1, text, content)
    local res, err = client.decode_json(content)
    if not res then
        notify(err .. ":\n" .. content:sub(1, 300), vim.log.levels.ERROR)
        return
    end
    review.start(buf, r1, c1, text, res)
end

function handlers.replace(_, buf, r1, c1, _, content, r2, c2)
    api.nvim_buf_set_text(buf, r1, c1, r2, c2, vim.split(vim.trim(content), "\n", { plain = true }))
end

function handlers.float(skill, _, _, _, _, content)
    review.show_text(skill.label or skill.name, vim.split(content, "\n", { plain = true }))
end

function M.run(skill, sel)
    local buf = sel.buf
    local mark = api.nvim_buf_set_extmark(buf, ns_sel, sel.sr, sel.sc, {
        end_row = sel.er,
        end_col = sel.ec,
        hl_group = "OllamaPending",
        end_right_gravity = false,
    })
    local stop_spinner = start_spinner(buf, mark, skill)

    client.chat(M.config, skill, sel.text, function(err, content)
        stop_spinner()
        if not api.nvim_buf_is_valid(buf) then return end
        local m = api.nvim_buf_get_extmark_by_id(buf, ns_sel, mark, { details = true })
        api.nvim_buf_clear_namespace(buf, ns_sel, 0, -1)
        if err then
            return notify(skill.name .. ": " .. err, vim.log.levels.ERROR)
        end
        if not m or not m[1] then
            return notify(skill.name .. ": zaznaczony fragment zniknął", vim.log.levels.WARN)
        end
        local r1, c1, r2, c2 = m[1], m[2], m[3].end_row, m[3].end_col
        local now = table.concat(api.nvim_buf_get_text(buf, r1, c1, r2, c2, {}), "\n")
        if now ~= sel.text then
            return notify(skill.name .. ": tekst zmienił się w trakcie przetwarzania — przerwano", vim.log.levels.WARN)
        end
        local h = handlers[skill.handler or "float"]
        if not h then
            return notify("nieznany handler: " .. tostring(skill.handler), vim.log.levels.ERROR)
        end
        h(skill, buf, r1, c1, sel.text, content, r2, c2)
    end)
end

function M.pick()
    local sel, err = get_selection()
    api.nvim_feedkeys(api.nvim_replace_termcodes("<Esc>", true, false, true), "nx", false)
    if not sel then return notify(err, vim.log.levels.WARN) end
    if vim.trim(sel.text) == "" then return notify("puste zaznaczenie", vim.log.levels.WARN) end

    vim.ui.select(M.skills, {
        prompt = "Ollama skill:",
        format_item = function(s) return s.label or s.name end,
    }, function(skill)
        if skill then M.run(skill, sel) end
    end)
end

function M.setup(opts)
    M.config = vim.tbl_deep_extend("force", M.config, opts or {})
    M.skills = vim.list_extend(vim.deepcopy(require("czandal.ollama.skills")), M.config.skills)

    review.setup_highlights()
    api.nvim_create_autocmd("ColorScheme", {
        group = api.nvim_create_augroup("czandal_ollama_hl", { clear = true }),
        callback = review.setup_highlights,
    })

    vim.keymap.set("x", M.config.keymap, M.pick, { desc = "Ollama: uruchom skill na zaznaczeniu" })
    api.nvim_create_user_command("OllamaCancel", function()
        notify(("anulowano %d zapytań"):format(client.cancel_all()))
    end, {})
end

return M
