-- Inline diff review of korektor suggestions.
local diff = require("czandal.ollama.diff")
local api = vim.api

local M = {}

local ns_track = api.nvim_create_namespace("czandal_ollama_track")
local ns_deco = api.nvim_create_namespace("czandal_ollama_deco")
local sessions = {}

local KEYS = {
    { "]c", "następna zmiana" },
    { "[c", "poprzednia zmiana" },
    { "ga", "zastosuj zmianę" },
    { "gr", "odrzuć zmianę" },
    { "gA", "zastosuj wszystkie" },
    { "gR", "odrzuć wszystkie" },
    { "q", "zakończ przegląd" },
}

---------------------------------------------------------------------------
-- highlights
---------------------------------------------------------------------------
local function get_hl(name)
    local ok, h = pcall(api.nvim_get_hl, 0, { name = name, link = false })
    return ok and h or {}
end

function M.setup_highlights()
    local del, add = get_hl("DiffDelete"), get_hl("DiffAdd")
    local red = get_hl("Removed").fg or get_hl("DiagnosticError").fg or 0xeb6f92
    local green = get_hl("Added").fg or get_hl("DiagnosticOk").fg or 0x9ccfd8
    local set = api.nvim_set_hl
    set(0, "OllamaDel", { fg = red, bg = del.bg, strikethrough = true })
    set(0, "OllamaAdd", { fg = green, bg = add.bg })
    set(0, "OllamaDelCur", { fg = red, bg = del.bg, strikethrough = true, bold = true, underline = true, sp = red })
    set(0, "OllamaAddCur", { fg = green, bg = add.bg, bold = true, underline = true, sp = green })
    set(0, "OllamaDelText", { fg = red })
    set(0, "OllamaAddText", { fg = green })
    set(0, "OllamaPending", { link = "Visual", default = true })
end

---------------------------------------------------------------------------
-- helpers
---------------------------------------------------------------------------
local function display(s)
    return (s:gsub("\n", "⏎"))
end

local function wrap(text, width, indent)
    indent = indent or ""
    local out, line = {}, ""
    for word in text:gmatch("%S+") do
        local cand = line == "" and word or (line .. " " .. word)
        if line ~= "" and vim.fn.strdisplaywidth(cand) > width then
            out[#out + 1] = line
            line = indent .. word
        else
            line = cand
        end
    end
    if line ~= "" then out[#out + 1] = line end
    return out
end

--- Convert byte offset in `text` (which starts at sr, sc) to buffer pos.
local function pos_at(text, sr, sc, off)
    local nl, last = 0, 0
    for i in text:sub(1, off):gmatch("()\n") do
        nl, last = nl + 1, i
    end
    if nl == 0 then return sr, sc + off end
    return sr + nl, off - last
end

local function get_range(s, ch)
    local m = api.nvim_buf_get_extmark_by_id(s.buf, ns_track, ch.id, { details = true })
    if not m or not m[1] then return nil end
    return m[1], m[2], m[3].end_row or m[1], m[3].end_col or m[2]
end

local function buf_text(buf, r1, c1, r2, c2)
    local ok, lines = pcall(api.nvim_buf_get_text, buf, r1, c1, r2, c2, {})
    return ok and table.concat(lines, "\n") or nil
end

local function win_for(buf)
    if api.nvim_win_get_buf(0) == buf then return api.nvim_get_current_win() end
    local w = vim.fn.bufwinid(buf)
    return w ~= -1 and w or nil
end

--- Generic centered, focused float with q/<Esc>/<CR> to close.
function M.show_text(title, lines, hls)
    local width = 20
    for _, l in ipairs(lines) do width = math.max(width, vim.fn.strdisplaywidth(l)) end
    width = math.min(width, math.floor(vim.o.columns * 0.8))
    local height = math.min(#lines, math.floor(vim.o.lines * 0.7))
    local b = api.nvim_create_buf(false, true)
    api.nvim_buf_set_lines(b, 0, -1, false, lines)
    for _, h in ipairs(hls or {}) do
        vim.hl.range(b, ns_deco, h[2], { h[1], 0 }, { h[1], -1 })
    end
    vim.bo[b].modifiable = false
    vim.bo[b].bufhidden = "wipe"
    local w = api.nvim_open_win(b, true, {
        relative = "editor",
        width = width,
        height = height,
        row = math.floor((vim.o.lines - height) / 2) - 1,
        col = math.floor((vim.o.columns - width) / 2),
        style = "minimal",
        border = "rounded",
        title = " " .. title .. " ",
        title_pos = "center",
    })
    vim.wo[w].wrap = true
    vim.wo[w].linebreak = true
    for _, k in ipairs({ "q", "<Esc>", "<CR>" }) do
        vim.keymap.set("n", k, function() pcall(api.nvim_win_close, w, true) end, { buffer = b, nowait = true })
    end
    api.nvim_create_autocmd("WinLeave", {
        buffer = b,
        once = true,
        callback = function() pcall(api.nvim_win_close, w, true) end,
    })
    return w
end

---------------------------------------------------------------------------
-- rendering
---------------------------------------------------------------------------
local function close_float(s)
    if s.float and api.nvim_win_is_valid(s.float) then
        api.nvim_win_close(s.float, true)
    end
    s.float = nil
end

local function pending_count(s)
    local n = 0
    for _, ch in ipairs(s.changes) do
        if ch.state == "pending" then n = n + 1 end
    end
    return n
end

local function render(s)
    api.nvim_buf_clear_namespace(s.buf, ns_deco, 0, -1)
    for i, ch in ipairs(s.changes) do
        if ch.state == "pending" then
            local r1, c1, r2, c2 = get_range(s, ch)
            if r1 then
                local cur = i == s.cur
                if r1 ~= r2 or c1 ~= c2 then
                    api.nvim_buf_set_extmark(s.buf, ns_deco, r1, c1, {
                        end_row = r2,
                        end_col = c2,
                        hl_group = cur and "OllamaDelCur" or "OllamaDel",
                        priority = 200,
                    })
                end
                if ch.new ~= "" then
                    api.nvim_buf_set_extmark(s.buf, ns_deco, r2, c2, {
                        virt_text = { { display(ch.new), cur and "OllamaAddCur" or "OllamaAdd" } },
                        virt_text_pos = "inline",
                        right_gravity = false,
                        priority = 200,
                    })
                end
                api.nvim_buf_set_extmark(s.buf, ns_deco, r1, 0, {
                    sign_text = cur and "▶" or "●",
                    sign_hl_group = cur and "OllamaAddText" or "OllamaDelText",
                    priority = cur and 210 or 200,
                })
            end
        end
    end
end

local function show_float(s)
    close_float(s)
    local ch = s.changes[s.cur]
    if not ch or ch.state ~= "pending" then return end
    local r1, c1 = get_range(s, ch)
    local win = win_for(s.buf)
    if not r1 or not win then return end

    local width = math.max(40, math.min(70, api.nvim_win_get_width(win) - 4))
    local lines, hls = {}, {}
    local function add(text, hl)
        lines[#lines + 1] = text
        if hl then hls[#hls + 1] = { #lines - 1, hl } end
    end
    if ch.old ~= "" then
        for _, l in ipairs(wrap("- " .. display(ch.old), width, "  ")) do add(l, "OllamaDelText") end
    end
    if ch.new ~= "" then
        for _, l in ipairs(wrap("+ " .. display(ch.new), width, "  ")) do add(l, "OllamaAddText") end
    end
    if ch.why ~= "" then
        add("")
        for _, l in ipairs(wrap(ch.why, width)) do add(l) end
    end
    add("")
    add("ga zastosuj · gr odrzuć · ]c [c · gA/gR wszystkie · q", "Comment")

    local real_w = 0
    for _, l in ipairs(lines) do real_w = math.max(real_w, vim.fn.strdisplaywidth(l)) end

    local b = api.nvim_create_buf(false, true)
    api.nvim_buf_set_lines(b, 0, -1, false, lines)
    for _, h in ipairs(hls) do
        vim.hl.range(b, ns_deco, h[2], { h[1], 0 }, { h[1], -1 })
    end
    vim.bo[b].bufhidden = "wipe"

    s.float = api.nvim_open_win(b, false, {
        relative = "win",
        win = win,
        bufpos = { r1, c1 },
        row = 1,
        col = 0,
        width = math.min(real_w, width),
        height = #lines,
        style = "minimal",
        border = "rounded",
        focusable = false,
        noautocmd = true,
        zindex = 60,
        title = (" [%d/%d] %s · zostało %d "):format(s.cur, #s.changes, ch.typ, pending_count(s)),
        title_pos = "left",
    })
end

local function refresh(s)
    render(s)
    show_float(s)
end

---------------------------------------------------------------------------
-- navigation & actions
---------------------------------------------------------------------------
local function change_at_cursor(s)
    local win = win_for(s.buf)
    if not win then return nil end
    local cur = api.nvim_win_get_cursor(win)
    local row, col = cur[1] - 1, cur[2]
    for i, ch in ipairs(s.changes) do
        if ch.state == "pending" then
            local r1, c1, r2, c2 = get_range(s, ch)
            if r1 then
                local after_start = row > r1 or (row == r1 and col >= c1)
                local before_end = row < r2 or (row == r2 and col <= c2)
                if after_start and before_end then return i end
            end
        end
    end
end

local function goto_change(s, i)
    s.cur = i
    local r1, c1 = get_range(s, s.changes[i])
    local win = win_for(s.buf)
    if r1 and win then
        s.moving = true
        api.nvim_win_set_cursor(win, { r1 + 1, c1 })
        s.moving = false
    end
    refresh(s)
end

local function step(s, dir)
    local n = #s.changes
    for k = 1, n do
        local i = ((s.cur - 1 + dir * k) % n) + 1
        if s.changes[i].state == "pending" then
            return goto_change(s, i)
        end
    end
end

local finish

local function apply_one(s, ch)
    local r1, c1, r2, c2 = get_range(s, ch)
    if not r1 then return false end
    if buf_text(s.buf, r1, c1, r2, c2) ~= ch.old then
        vim.notify("korektor: tekst w miejscu zmiany został zmieniony — pomijam", vim.log.levels.WARN)
        return false
    end
    api.nvim_buf_set_text(s.buf, r1, c1, r2, c2, vim.split(ch.new, "\n", { plain = true }))
    return true
end

local function resolve(s, i, ch, apply)
    if apply and apply_one(s, ch) then
        ch.state = "applied"
        s.applied = s.applied + 1
    else
        ch.state = "rejected"
        s.rejected = s.rejected + 1
    end
    api.nvim_buf_del_extmark(s.buf, ns_track, ch.id)
    s.cur = i
end

local function act(s, apply)
    local i = change_at_cursor(s) or s.cur
    local ch = s.changes[i]
    if not ch or ch.state ~= "pending" then return step(s, 1) end
    resolve(s, i, ch, apply)
    if pending_count(s) == 0 then return finish(s) end
    step(s, 1)
end

local function act_all(s, apply)
    for i, ch in ipairs(s.changes) do
        if ch.state == "pending" then resolve(s, i, ch, apply) end
    end
    finish(s)
end

---------------------------------------------------------------------------
-- session lifecycle
---------------------------------------------------------------------------
local function set_keymaps(s)
    local handlers = {
        ["]c"] = function() step(s, 1) end,
        ["[c"] = function() step(s, -1) end,
        ["ga"] = function() act(s, true) end,
        ["gr"] = function() act(s, false) end,
        ["gA"] = function() act_all(s, true) end,
        ["gR"] = function() act_all(s, false) end,
        ["q"] = function() finish(s) end,
    }
    s.saved_maps = {}
    for _, k in ipairs(KEYS) do
        local lhs = k[1]
        local m = vim.fn.maparg(lhs, "n", false, true)
        if m and m.buffer == 1 then s.saved_maps[lhs] = m end
        vim.keymap.set("n", lhs, handlers[lhs], { buffer = s.buf, nowait = true, desc = "korektor: " .. k[2] })
    end
end

local function restore_keymaps(s)
    for _, k in ipairs(KEYS) do
        pcall(vim.keymap.del, "n", k[1], { buffer = s.buf })
    end
    if api.nvim_buf_is_valid(s.buf) then
        api.nvim_buf_call(s.buf, function()
            for _, m in pairs(s.saved_maps or {}) do
                pcall(vim.fn.mapset, m)
            end
        end)
    end
end

function M.stop(buf)
    local s = sessions[buf]
    if not s then return end
    sessions[buf] = nil
    close_float(s)
    pcall(api.nvim_del_augroup_by_id, s.augroup)
    if api.nvim_buf_is_valid(buf) then
        api.nvim_buf_clear_namespace(buf, ns_track, 0, -1)
        api.nvim_buf_clear_namespace(buf, ns_deco, 0, -1)
        restore_keymaps(s)
    end
    return s
end

local function show_summary(s)
    local lines, hls = {}, {}
    local function add(text, hl)
        lines[#lines + 1] = text
        if hl then hls[#hls + 1] = { #lines - 1, hl } end
    end
    local width = math.min(80, math.floor(vim.o.columns * 0.8))

    add("Ocena", "Title")
    for _, l in ipairs(wrap(type(s.ocena) == "string" and s.ocena or "(brak oceny)", width)) do add(l) end
    add("")
    local total = #s.changes
    if total == 0 then
        add("Brak zmian w tekście.", "OllamaAddText")
    else
        add(("Zastosowano: %d  ·  Odrzucono: %d  ·  Wszystkich: %d"):format(s.applied, s.rejected, total), "Comment")
    end
    if #s.unused > 0 then
        add("")
        add("Uwagi modelu bez zmiany w tekście:", "Title")
        for _, z in ipairs(s.unused) do
            add(("• [%s] %s → %s"):format(z.typ or "?", display(z.fragment_przed or ""), display(z.fragment_po or "")))
            if z.uzasadnienie and z.uzasadnienie ~= "" then
                for _, l in ipairs(wrap(z.uzasadnienie, width - 2)) do add("  " .. l, "Comment") end
            end
        end
    end
    M.show_text("Korekta — podsumowanie", lines, hls)
end

finish = function(s)
    M.stop(s.buf)
    show_summary(s)
end

--- Start a review session.
--- buf, sr, sc: buffer and 0-based start of the original text in it.
function M.start(buf, sr, sc, text, res)
    M.stop(buf)
    local zmiany = type(res.zmiany) == "table" and res.zmiany or {}
    local corrected = res.poprawiony_tekst
    if type(corrected) ~= "string" then
        corrected = diff.apply_zmiany(text, zmiany)
    end
    -- keep original leading/trailing whitespace (model tends to strip it)
    local lead, trail = text:match("^%s*"), text:match("%s*$")
    if #lead == #text then trail = "" end
    corrected = lead .. vim.trim(corrected) .. trail

    local hunks = diff.hunks(text, corrected)
    local unused = diff.annotate(text, hunks, zmiany)

    local s = {
        buf = buf,
        changes = {},
        cur = 1,
        applied = 0,
        rejected = 0,
        ocena = res.ocena,
        unused = unused,
    }
    for _, h in ipairs(hunks) do
        local r1, c1 = pos_at(text, sr, sc, h.s)
        local r2, c2 = pos_at(text, sr, sc, h.e)
        local empty = h.s == h.e
        local id = api.nvim_buf_set_extmark(buf, ns_track, r1, c1, {
            end_row = r2,
            end_col = c2,
            right_gravity = not empty,
            end_right_gravity = false,
        })
        s.changes[#s.changes + 1] = {
            id = id,
            old = h.old,
            new = h.new,
            typ = h.typ or "zmiana",
            why = h.uzasadnienie or "",
            state = "pending",
        }
    end

    if #s.changes == 0 then
        return show_summary(s)
    end

    sessions[buf] = s
    set_keymaps(s)
    s.augroup = api.nvim_create_augroup("czandal_ollama_review_" .. buf, { clear = true })
    api.nvim_create_autocmd("CursorMoved", {
        group = s.augroup,
        buffer = buf,
        callback = function()
            if s.moving then return end
            local i = change_at_cursor(s)
            if i and i ~= s.cur then
                s.cur = i
                refresh(s)
            end
        end,
    })
    api.nvim_create_autocmd({ "BufWinLeave", "BufUnload" }, {
        group = s.augroup,
        buffer = buf,
        callback = function() M.stop(buf) end,
    })
    goto_change(s, 1)
end

return M
