-- Word-level diff between original and corrected text.
local M = {}

local PUNCT_MB = {
    ["„"] = true, ["”"] = true, ["“"] = true, ["«"] = true, ["»"] = true,
    ["–"] = true, ["—"] = true, ["…"] = true, ["‚"] = true, ["’"] = true, ["‘"] = true,
}
local NBSP = "\194\160"

local function chars(s)
    local res, i, n = {}, 1, #s
    while i <= n do
        local b = s:byte(i)
        local len = (b < 0x80 and 1) or (b >= 0xF0 and 4) or (b >= 0xE0 and 3) or (b >= 0xC0 and 2) or 1
        res[#res + 1] = s:sub(i, i + len - 1)
        i = i + len
    end
    return res
end

local function class(c)
    if #c == 1 then
        if c:match("%s") then return "s" end
        if c:match("%p") then return "p" end
        return "w"
    end
    if c == NBSP then return "s" end
    if PUNCT_MB[c] then return "p" end
    return "w"
end

--- Split into tokens: words, whitespace runs, single punctuation chars.
function M.tokenize(s)
    local toks, cur, cur_class = {}, nil, nil
    for _, c in ipairs(chars(s)) do
        local k = class(c)
        if k == "p" then
            if cur then toks[#toks + 1] = cur end
            toks[#toks + 1] = c
            cur, cur_class = nil, nil
        elseif k == cur_class then
            cur = cur .. c
        else
            if cur then toks[#toks + 1] = cur end
            cur, cur_class = c, k
        end
    end
    if cur then toks[#toks + 1] = cur end
    return toks
end

local function offsets(toks)
    local off, pos = {}, 0
    for i, t in ipairs(toks) do
        off[i] = pos
        pos = pos + #t
    end
    off[#toks + 1] = pos
    return off
end

local function to_lines(toks)
    local out = {}
    for i, t in ipairs(toks) do
        out[i] = (t:gsub("\n", "\1"))
    end
    return table.concat(out, "\n") .. "\n"
end

local text_diff = (vim.text and vim.text.diff) or vim.diff

--- Hunks { s, e, old, new } with 0-based byte offsets [s, e) into `a`.
function M.hunks(a, b)
    if a == b then return {} end
    local ta, tb = M.tokenize(a), M.tokenize(b)
    local oa, ob = offsets(ta), offsets(tb)
    local idx = text_diff(to_lines(ta), to_lines(tb), { result_type = "indices", algorithm = "histogram" })
    local res = {}
    for _, h in ipairs(idx) do
        local sa, ca, sb, cb = h[1], h[2], h[3], h[4]
        local as = ca == 0 and oa[sa + 1] or oa[sa]
        local ae = ca == 0 and as or oa[sa + ca]
        local bs = cb == 0 and ob[sb + 1] or ob[sb]
        local be = cb == 0 and bs or ob[sb + cb]
        local old, new = a:sub(as + 1, ae), b:sub(bs + 1, be)
        -- the model often reflows/collapses whitespace; ignore such hunks
        if not (old:match("^%s*$") and new:match("^%s*$")) then
            res[#res + 1] = { s = as, e = ae, old = old, new = new }
        end
    end
    return res
end

--- Find occurrences of `f` in `a` ignoring all whitespace.
--- Returns list of { s, e } 0-based byte ranges into `a`.
local function find_loose(a, f)
    local stripped, map = {}, {}
    for i = 1, #a do
        local c = a:sub(i, i)
        if not c:match("%s") then
            stripped[#stripped + 1] = c
            map[#stripped] = i
        end
    end
    local sa = table.concat(stripped)
    local sf = f:gsub("%s", "")
    local res, init = {}, 1
    if sf == "" then return res end
    while true do
        local s, e = sa:find(sf, init, true)
        if not s then break end
        res[#res + 1] = { s = map[s] - 1, e = map[e] }
        init = s + 1
    end
    return res
end

--- Attach typ/uzasadnienie from model `zmiany` to hunks (smallest overlapping
--- fragment wins). Returns the zmiany that matched no hunk.
function M.annotate(a, hunks, zmiany)
    local located = {}
    for i, z in ipairs(zmiany) do
        local f = z.fragment_przed
        if type(f) == "string" and f ~= "" then
            local init, found = 1, false
            while true do
                local s, e = a:find(f, init, true)
                if not s then break end
                located[#located + 1] = { z = z, i = i, s = s - 1, e = e }
                init, found = s + 1, true
            end
            if not found then
                for _, r in ipairs(find_loose(a, f)) do
                    located[#located + 1] = { z = z, i = i, s = r.s, e = r.e }
                end
            end
        end
    end

    local used = {}
    for _, h in ipairs(hunks) do
        local best
        for _, l in ipairs(located) do
            local overlap
            if h.s < h.e then
                overlap = l.s < h.e and h.s < l.e
            else
                overlap = l.s <= h.s and h.s <= l.e
            end
            if overlap and (not best or (l.e - l.s) < (best.e - best.s)) then
                best = l
            end
        end
        if best then
            h.typ = best.z.typ
            h.uzasadnienie = best.z.uzasadnienie
            used[best.i] = true
        end
    end

    local unused = {}
    for i, z in ipairs(zmiany) do
        if not used[i] then unused[#unused + 1] = z end
    end
    return unused
end

--- Build corrected text from zmiany when the model omitted poprawiony_tekst.
function M.apply_zmiany(a, zmiany)
    local out = a
    for _, z in ipairs(zmiany) do
        local f, t = z.fragment_przed, z.fragment_po
        if type(f) == "string" and f ~= "" and type(t) == "string" then
            local s, e = out:find(f, 1, true)
            if s then out = out:sub(1, s - 1) .. t .. out:sub(e + 1) end
        end
    end
    return out
end

return M
