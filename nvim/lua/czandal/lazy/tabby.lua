return {
    "TabbyML/vim-tabby",
    lazy = false,
    dependencies = {
      "neovim/nvim-lspconfig",
    },
    init = function()
      vim.g.tabby_agent_start_command = {"npx", "tabby-agent", "--stdio"}
      vim.g.tabby_inline_completion_trigger = "auto"
      vim.g.tabby_inline_completion_keybinding_accept = "<C-S>"
      vim.g.tabby_inline_completion_keybinding_trigger_or_dismiss = "<C-R>"
      -- In your lspconfig setup for tabby
vim.lsp.config("tabby", {
    capabilities = {
        textDocument = {
            inlineCompletion = { dynamicRegistration = true }
        }
    }
})

    end,
}
