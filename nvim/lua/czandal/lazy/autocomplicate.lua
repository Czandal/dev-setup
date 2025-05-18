return {
    "Czandal/autocomplicate.nvim",
    name = "autocomplicate",
    config = function()
        require("autocomplicate").setup({
            register_autocmd = true,
            default_keymaps = true,
            model = "deepseek-coder-v2:latest",
            host= "http://localhost:11445",
            context_line_size = 250,
            llm_options = {
                num_predict = 15,
                temperature = 0.7,
                top_k = 30,
                top_p = 0.8,
                stop = "\n"
            },
            enable_logging = true,
            log_to_console = false,
            path_to_log = "~/CodeShit/dev-setup/autocomplicate.log"
        })
    end
}
