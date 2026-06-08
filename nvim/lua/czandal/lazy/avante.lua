return {
    "yetone/avante.nvim",
    event = "VeryLazy",
    lazy = false,
    version = false, -- Use latest for Morph/fast merge support
    build = "make",
    opts = {
        provider = "claude",                 -- Primary for fast merge
        auto_suggestions_provider = "claude", -- Fallback for suggestions
        behaviour = {
            auto_set_highlight_group = true,
            auto_set_keymaps = true,
            auto_apply_diff_after_generation = false,
            minimize_diff = true,
            enable_fastapply = true,  -- Enable Fast Apply feature
        },
        mappings = {
            diff = {
                ours = "co",
                theirs = "ct",
                all_theirs = "ca",
                both = "cb",
                cursor = "cc",
                next = "]x",
                prev = "[x",
            },
            suggestion = {
                accept = "<M-l>",
                next = "<M-]>",
                prev = "<M-[>",
                dismiss = "<C-]>",
            },
            jump = {
                next = "]]",
                prev = "[[",
            },
            submit = {
                normal = "<CR>",
                insert = "<C-s>",
            },
            sidebar = {
                apply_all = "A",
                apply_cursor = "a",
                switch_windows = "<Tab>",
                reverse_switch_windows = "<S-Tab>",
            },
        },
        hints = { enabled = true },
        windows = {
            position = "right",
            wrap = true,
            width = 30,
            sidebar_header = {
                enabled = true,
                align = "center",
                rounded = true,
            },
        },
        providers = {
            morph = {
                model = "auto"
            },
            claude = {
                endpoint = "https://api.anthropic.com",
                model = "claude-sonnet-4-6",
            },
            timeout = 30000,                  -- Timeout in milliseconds
        },
    },
    dependencies = {
        "stevearc/dressing.nvim",
        "nvim-lua/plenary.nvim",
        "MunifTanjim/nui.nvim",
        "MeanderingProgrammer/render-markdown.nvim",
        {
            "HakonHarnes/img-clip.nvim",
            event = "VeryLazy",
            opts = {
                default = {
                    embed_image_as_base64 = false,
                    prompt_for_file_name = false,
                    drag_and_drop = {
                        insert_mode = true,
                    },
                },
            },
        },
        "echasnovski/mini.pick", -- File picker
    },
}
