return {
    "Czandal/autocomplicate.nvim",
    name = "autocomplicate",
    config = function()
        require("autocomplicate").setup({
            register_autocmd = true,
            default_keymaps = true,
            model = "qwen2.5-coder:1.5b",
            -- host= "http://localhost:11445",
            context_line_size = 5,
            llm_options = {
                num_predict = 10,
                temperature = 0.7,
                top_k = 30,
                top_p = 0.8,

            },
        })
    end
}
