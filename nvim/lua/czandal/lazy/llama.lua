return {
    "ggml-org/llama.vim",
    event = "InsertEnter",
    init = function()
        vim.g.llama_config = {
            auto_fim = false,
			keymap_fim_accept_full = "<C-S>",
            keymap_fim_accept_line = "<C-L>",
            enable_at_startup = false,
            show_info = 0,
            n_predict = 128,
		    keymap_fim_trigger = "<C-Q>llfim",
		    keymap_fim_accept_word = "<C-Q>llw]",
		    keymap_inst_trigger = "<C-Q>i",
		    keymap_inst_rerun = "<C-Q>llre",
		    keymap_inst_continue = "<C-Q>llc",
		    keymap_inst_accept = "<Tab>",
		    keymap_inst_cancel = "<Esc>",
		    keymap_debug_toggle = "<C-Q>lld",
        }
        vim.api.nvim_set_hl(0, "llama_hl_fim_hint", {fg = "#908caa", ctermfg=209})
		vim.api.nvim_set_hl(0, "llama_hl_fim_info", {fg = "#50fa7b", ctermfg=119})
    end
}
