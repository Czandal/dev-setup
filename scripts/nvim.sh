#!/usr/bin/env bash
# desc: Neovim config, its dependencies, vivify, plugins
. "$(dirname "$0")/lib.sh" "$@"

step "Neovim dependencies"
# tree-sitter-cli and a C compiler build the parsers, ripgrep feeds telescope
have nvim || pkg neovim || true
pkg "ripgrep tree-sitter-cli gcc git curl" "ripgrep tree-sitter-cli build-essential git curl" || true
if have nvim && ! nvim --headless -c 'lua if vim.fn.has("nvim-0.12") == 0 then vim.cmd.cquit() end' +qa 2>/dev/null; then
    warn "this config needs Neovim 0.12+, get it from https://github.com/neovim/neovim/releases"
fi

step "Config"
link "$ROOT/nvim" "$HOME/.config/nvim" || true

step "Vivify (markdown preview)"
if have viv; then
    say "already installed: viv"
elif ! aur vivify-bin; then
    say "download https://github.com/jannis-baum/vivify/releases and put viv + vivify-server on PATH"
fi

step "Plugins"
# LSP servers and codelldb are installed by Mason on first start
if have nvim && confirm "Install plugins at the versions from lazy-lock.json?"; then
    run nvim --headless "+Lazy! restore" +qa
fi

say "zig + zls: ./setup mise    completions: ./setup llm"
