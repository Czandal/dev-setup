return {
    "Robitx/gp.nvim",
    config = function()
        require("gp").setup({
            providers = {
                myllama = {
                    endpoint = "http://localhost:11434/v1/chat/completions",
                    secret = "foo"
                }
            },
            agents = {
                {
                    name = "ChatGPT4o",
                    disable = true,
                },
                {
                    provider = "openai",
                    name = "ChatGPT4o-mini",
                    disable = true,
                },
                {
                    provider = "copilot",
                    name = "ChatCopilot",
                    disable = true,
                },
                {
                    provider = "googleai",
                    name = "ChatGemini",
                    disable = true,
                },
                {
                    provider = "pplx",
                    name = "ChatPerplexityLlama3.1-8B",
                    disable = true,
                },
                {
                    provider = "anthropic",
                    name = "ChatClaude-3-5-Sonnet",
                    disable = true,
                },
                {
                    provider = "anthropic",
                    name = "ChatClaude-3-Haiku",
                    disable = true,
                },
                {
                    provider = "ollama",
                    name = "ChatOllamaLlama3.1-8B",
                    disable = true,
                },
                {
                    provider = "lmstudio",
                    name = "ChatLMStudio",
                    disable = true,
                },
                {
                    provider = "openai",
                    name = "CodeGPT4o",
                    disable = true,
                },
                {
                    provider = "openai",
                    name = "CodeGPT4o-mini",
                    disable = true,
                },
                {
                    provider = "copilot",
                    name = "CodeCopilot",
                    disable = true,
                },
                {
                    provider = "googleai",
                    name = "CodeGemini",
                    disable = true,
                },
                {
                    provider = "pplx",
                    name = "CodePerplexityLlama3.1-8B",
                    disable = true,
                },
                {
                    provider = "anthropic",
                    name = "CodeClaude-3-5-Sonnet",
                    disable = true,
                },
                {
                    provider = "anthropic",
                    name = "CodeClaude-3-Haiku",
                    disable = true,
                },
                {
                    provider = "ollama",
                    name = "CodeOllamaLlama3.1-8B",
                    disable = true,
                },
                {
                    provider      = "myllama",
                    name          = "codellama:13b",
                    chat          = false,
                    command       = true,
                    -- string with model name or table with model name and parameters
                    model         = {
                        model = "codellama:13b",
                        temperature = 0.8,
                        top_p = 1,
                        min_p = 0.05,
                    },
                    -- system prompt (use this to specify the persona/role of the AI)
                    system_prompt = "You are an AI working as a code editor.\n\n"
                        .. "DO NOT USE COMMENTARY OUTSIDE OF THE SNIPPET RESPONSE.\n RESPOND ONLY IN CODE MATCHING THE PROGRAMMING LANGUAGE"
                        .. "START AND END YOUR ANSWER WITH (NOTHING ELSE):```",
                },
                {
                    provider = "myllama",
                    name = "mistral:7b",
                    chat = true,
                    command = false,
                    -- string with model name or table with model name and parameters
                    model = {
                        model = "mistral:7b",
                        temperature = 0.4,
                        top_p = 1,
                        min_p = 0.05,
                    },
                    -- system prompt (use this to specify the persona/role of the AI)
                    system_prompt =
                    "You are general AI assistant, extremely well versed in coding, software development etc",
                },
            },
            default_command_agent = "codellama:13b",
            default_chat_agent = "mistral:7b",
            vault = {
                enabled = false -- This disables the API key requirement
            }
        })
        -- Keymaps
        vim.keymap.set("v", "<C-g>r", ":'<,'>GpRewrite<CR>")
        -- Implement based on the comment
        vim.keymap.set("v", "<C-g>i", ":'<,'>GpImplement<CR>")
        -- Append the code
        vim.keymap.set("v", "<C-g>a", ":'<,'>GpAppend<CR>")
        -- Access the context
        vim.keymap.set("n", "<C-g>c", ":GpContext<CR>", {silent = true})
        -- Chat managing
        vim.keymap.set("n", "<C-s>f", ":GpChatFinder<CR>")
        vim.keymap.set("n", "<C-s>n", ":GpChatNew<CR>")
        vim.keymap.set("n", "<C-s>t", ":GpChatToggle<CR>")
        vim.keymap.set("n", "<C-s>d", ":GpChatDelete<CR>")

    end
}
