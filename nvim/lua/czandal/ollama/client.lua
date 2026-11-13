local M = {}

local jobs = {}

--- Async call to Ollama /api/chat. cb(err, content) runs on the main loop.
function M.chat(cfg, skill, text, cb)
    local messages = {}
    if skill.system then
        messages[#messages + 1] = { role = "system", content = skill.system }
    end
    messages[#messages + 1] = { role = "user", content = skill.prompt and skill.prompt(text) or text }

    local body = vim.json.encode({
        model = skill.model,
        messages = messages,
        stream = false,
        format = skill.format,
        options = skill.options,
    })

    local job
    job = vim.system({
        "curl", "-sS", "-X", "POST", cfg.host .. "/api/chat",
        "-H", "Content-Type: application/json",
        "--data-binary", "@-",
    }, { stdin = body, text = true, timeout = cfg.timeout }, function(r)
        jobs[job] = nil
        vim.schedule(function()
            if r.signal ~= 0 or r.code == 124 then
                return cb("przerwano (timeout lub anulowanie)")
            end
            if r.code ~= 0 then
                return cb(("curl (%d): %s"):format(r.code, vim.trim(r.stderr or "")))
            end
            local ok, resp = pcall(vim.json.decode, r.stdout or "")
            if not ok or type(resp) ~= "table" then
                return cb("niepoprawna odpowiedź Ollama: " .. (r.stdout or ""):sub(1, 200))
            end
            if resp.error then
                return cb("Ollama: " .. tostring(resp.error))
            end
            cb(nil, resp.message and resp.message.content or "")
        end)
    end)
    jobs[job] = true
    return job
end

function M.cancel_all()
    local n = 0
    for job in pairs(jobs) do
        job:kill(15)
        n = n + 1
    end
    return n
end

local DECODE_OPTS = { luanil = { object = true, array = true } }

--- Decode JSON from model output, tolerating text around the object.
function M.decode_json(s)
    local ok, v = pcall(vim.json.decode, s, DECODE_OPTS)
    if ok and type(v) == "table" then
        return v
    end
    local inner = s:match("%b{}")
    if inner then
        ok, v = pcall(vim.json.decode, inner, DECODE_OPTS)
        if ok and type(v) == "table" then
            return v
        end
    end
    return nil, "model nie zwrócił poprawnego JSON"
end

return M
