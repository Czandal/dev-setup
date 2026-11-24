#!/usr/bin/env bash
# desc: Neovim config, its dependencies, md-to-pdf, plugins
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

step "md-to-pdf (markdown -> HTML -> PDF through puppeteer, :MdPdf)"
# puppeteer drives the system browser, its own Chromium download is skipped
have chromium || have chromium-browser || have google-chrome-stable || pkg chromium || true
if have md-to-pdf; then
    say "already installed: md-to-pdf"
elif have mise; then
    if ! mise which npm >/dev/null 2>&1 && [ "$DRY_RUN" != 1 ]; then
        say "needs node: ./setup mise --tools, then rerun"
    elif confirm "Install md-to-pdf with mise?" \
        && ! run env PUPPETEER_SKIP_DOWNLOAD=1 mise use -g npm:md-to-pdf@5; then
        # Never bypassed from here: read the error above, check the release it
        # names, and only then exempt that one version yourself.
        warn "mise refused md-to-pdf. If it is the trust policy on a puppeteer dependency:"
        say "review the package@version it names, then put under [tools] in ~/.config/mise/config.toml"
        say '  "npm:md-to-pdf" = { version = "5", trust_policy_excludes = ["<package>@<version>"] }'
        say "and run: PUPPETEER_SKIP_DOWNLOAD=1 mise install"
    fi
elif have npm; then
    confirm "Install md-to-pdf with npm -g?" && run env PUPPETEER_SKIP_DOWNLOAD=1 npm install -g 'md-to-pdf@^5.2.5'
else
    say "needs node: ./setup mise --tools, then rerun"
fi

step "Plugins"
# LSP servers and codelldb are installed by Mason on first start
if have nvim && confirm "Install plugins at the versions from lazy-lock.json?"; then
    run nvim --headless "+Lazy! restore" +qa
fi

say "zig + zls: ./setup mise    completions: ./setup llm"
