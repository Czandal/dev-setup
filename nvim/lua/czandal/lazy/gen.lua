return {
    "David-Kunz/gen.nvim",
    opts = {
        model = "gemma3:12b-it-q4_K_M", -- The default model to use.
        quit_map = "q", -- set keymap to close the response window
        retry_map = "<c-r>", -- set keymap to re-send the current prompt
        accept_map = "<c-cr>", -- set keymap to replace the previous selection with the last result
        host = "localhost", -- The host running the Ollama service.
        port = "11434", -- The port on which the Ollama service is listening.
        display_mode = "float", -- The display mode. Can be "float" or "split" or "horizontal-split" or "vertical-split".
        show_prompt = false, -- Shows the prompt submitted to Ollama. Can be true (3 lines) or "full".
        show_model = true, -- Displays which model you are using at the beginning of your chat session.
        no_auto_close = true, -- Never closes the window automatically.
        file = false, -- Write the payload to a temporary file to keep the command short.
        hidden = false, -- Hide the generation window (if true, will implicitly set `prompt.replace = true`), requires Neovim >= 0.10
        result_filetype = "markdown", -- Configure filetype of the result buffer
        debug = false -- Prints errors and the command which is run.
    }
}
