return {
  "ray-x/go.nvim",
  dependencies = { -- optional packages
    "ray-x/guihua.lua",
    "neovim/nvim-lspconfig",
    { "nvim-treesitter/nvim-treesitter", branch = "main" },
  },
  opts = {
    lsp_cfg = true,
    -- Highlighting is handled by treesitter (see treesitter.lua). gopls semantic
    -- tokens are left off: on Neovim 0.12 gopls does not advertise a
    -- semanticTokensProvider here, and go.nvim's on_attach throws when enabling
    -- them. Treesitter gives proper identifier/function-name highlighting anyway.
    lsp_semantic_highlights = false,
  },
  config = function(_, opts)
    require("go").setup(opts)

    local format_sync_grp = vim.api.nvim_create_augroup("GoFormat", {})
    vim.api.nvim_create_autocmd("BufWritePre", {
      pattern = "*.go",
      callback = function()
        require("go.format").goimports()
      end,
      group = format_sync_grp,
    })
  end,
  event = { "CmdlineEnter" },
  ft = { "go", "gomod" },
  build = ':lua require("go.install").update_all_sync()', -- install/update all binaries
}
