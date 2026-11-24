-- Markdown -> HTML -> PDF through md-to-pdf (Puppeteer, headless Chromium).
--   :MdPdf[!]    write <file>.pdf next to the markdown file (! opens it)
--   :MdHtml[!]   write the styled <file>.html instead (! opens it)
--   :MdPreview   toggle: open the PDF and re-render it on every save
-- Styling lives in nvim/md-to-pdf/ (config.js, style.css); front-matter in a
-- document overrides it. Install: ./setup nvim
local M = {}

M.config = {
    cmd = "md-to-pdf",
    config_file = vim.fn.stdpath("config") .. "/md-to-pdf/config.js",
    -- used when PUPPETEER_EXECUTABLE_PATH is not set, first one found wins
    browsers = { "chromium", "chromium-browser", "google-chrome-stable", "google-chrome" },
    timeout = 120000, -- ms
}

local group = vim.api.nvim_create_augroup("czandal_mdpdf", { clear = true })
local state = {} -- bufnr -> { running, again, preview }

local function notify(msg, level)
    vim.notify(msg, level or vim.log.levels.INFO, { title = "md-to-pdf" })
end

local function browser()
    if vim.env.PUPPETEER_EXECUTABLE_PATH then
        return vim.env.PUPPETEER_EXECUTABLE_PATH
    end
    for _, name in ipairs(M.config.browsers) do
        local path = vim.fn.exepath(name)
        if path ~= "" then
            return path
        end
    end
end

--- Render the file of `buf`. opts: { html = bool, open = bool, quiet = bool }
function M.render(buf, opts)
    opts = opts or {}
    buf = (buf == nil or buf == 0) and vim.api.nvim_get_current_buf() or buf
    local src = vim.api.nvim_buf_get_name(buf)
    if src == "" or vim.fn.filereadable(src) == 0 then
        return notify("save the file first", vim.log.levels.WARN)
    end
    if vim.fn.executable(M.config.cmd) == 0 then
        return notify(M.config.cmd .. " not found, run ./setup nvim", vim.log.levels.ERROR)
    end

    local st = state[buf] or {}
    state[buf] = st
    if st.running then
        st.again = opts -- a save during a render: run once more when it ends
        return
    end
    st.running = true

    local cmd = { M.config.cmd, "--config-file", M.config.config_file }
    if opts.html then
        cmd[#cmd + 1] = "--as-html"
    end
    cmd[#cmd + 1] = src
    local out = vim.fn.fnamemodify(src, ":r") .. (opts.html and ".html" or ".pdf")

    vim.system(cmd, {
        cwd = vim.fs.dirname(src), -- images resolve relative to the document
        env = { PUPPETEER_EXECUTABLE_PATH = browser() },
        text = true,
        timeout = M.config.timeout,
    }, vim.schedule_wrap(function(r)
        st.running = false
        if r.code ~= 0 then
            local err = vim.trim((r.stderr or "") .. "\n" .. (r.stdout or ""))
            notify("failed (" .. r.code .. "):\n" .. err, vim.log.levels.ERROR)
        else
            if not opts.quiet then
                notify("wrote " .. vim.fn.fnamemodify(out, ":~:."))
            end
            if opts.open then
                vim.ui.open(out)
            end
        end
        if st.again then
            local again = st.again
            st.again = nil
            M.render(buf, again)
        end
    end))
end

function M.toggle_preview(buf)
    buf = (buf == nil or buf == 0) and vim.api.nvim_get_current_buf() or buf
    local st = state[buf] or {}
    state[buf] = st
    vim.api.nvim_clear_autocmds({ group = group, buffer = buf })
    st.preview = not st.preview
    if not st.preview then
        return notify("preview off")
    end
    vim.api.nvim_create_autocmd("BufWritePost", {
        group = group,
        buffer = buf,
        callback = function() M.render(buf, { quiet = true }) end,
    })
    vim.api.nvim_create_autocmd("BufWipeout", {
        group = group,
        buffer = buf,
        callback = function() state[buf] = nil end,
    })
    M.render(buf, { open = true }) -- the viewer reloads the file on later saves
end

function M.setup(opts)
    M.config = vim.tbl_deep_extend("force", M.config, opts or {})
    local cmd = vim.api.nvim_create_user_command
    cmd("MdPdf", function(a) M.render(0, { open = a.bang }) end, { bang = true, desc = "Markdown -> PDF" })
    cmd("MdHtml", function(a) M.render(0, { html = true, open = a.bang }) end, { bang = true, desc = "Markdown -> HTML" })
    cmd("MdPreview", function() M.toggle_preview(0) end, { desc = "Toggle PDF preview, re-render on save" })
end

return M
