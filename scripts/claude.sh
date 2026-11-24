#!/usr/bin/env bash
# desc: Claude Code: CLI, settings, CLAUDE.md, plugin and MCP servers
. "$(dirname "$0")/lib.sh" "$@"

ROOT_CLAUDE="$ROOT/claude"

# Claude Code reads ~/.claude/CLAUDE.md as one file, so it is generated: the
# public rules, plus claude/CLAUDE.local.md when that (gitignored) file exists.
# A copy rather than a symlink, because the local part must be merged in.
sync_claude_md() {
    local dst="$HOME/.claude/CLAUDE.md" tmp stamp
    tmp="$(mktemp)"
    cat "$ROOT_CLAUDE/CLAUDE.md" >"$tmp"
    if [ -f "$ROOT_CLAUDE/CLAUDE.local.md" ]; then
        printf '\n' >>"$tmp"
        cat "$ROOT_CLAUDE/CLAUDE.local.md" >>"$tmp"
    fi
    if { [ -e "$dst" ] || [ -L "$dst" ]; } && cmp -s "$tmp" "$dst"; then
        say "up to date: $dst"
        rm -f "$tmp"
        return 0
    fi
    if ! confirm "Write $dst (generated from claude/)?"; then
        rm -f "$tmp"
        return 1
    fi
    if [ -e "$dst" ] || [ -L "$dst" ]; then
        stamp="$(date +%Y%m%d%H%M%S)"
        run mv "$dst" "$dst.bak.$stamp"
    fi
    run mkdir -p "$(dirname "$dst")"
    run install -m 644 "$tmp" "$dst"
    rm -f "$tmp"
}

# mcp_server <name> -- asks for a URL and an optional token (empty = OAuth).
# Nothing is stored in this repo; the host and token only go to claude mcp add.
mcp_server() {
    local name="$1" url token
    if have claude && claude mcp get "$name" >/dev/null 2>&1; then
        say "already added: $name"
        return 0
    fi
    confirm "Add MCP server $name?" || return 0
    if [ "$DRY_RUN" = 1 ]; then
        say "would ask for the URL and token of $name"
        return 0
    fi
    read -r -p "   URL for $name (empty to skip): " url || url=""
    [ -n "$url" ] || return 0
    read -rs -p "   token for $name (empty for OAuth): " token || token=""
    echo
    say "adding $name"
    if [ -n "$token" ]; then
        claude mcp add --transport http --scope user "$name" "$url" \
            --header "Authorization: Bearer $token"
    else
        claude mcp add --transport http --scope user "$name" "$url"
    fi
}

step "Claude Code CLI"
if have claude; then
    say "already installed: $(claude --version 2>/dev/null | head -n1)"
elif [ "$PM" = pacman ]; then
    aur claude-code || warn "install claude-code yourself (AUR)"
elif confirm "Install Claude Code with the native installer (curl | bash)?"; then
    run sh -c 'curl -fsSL https://claude.ai/install.sh | bash'
fi

step "Claude Code settings"
link "$ROOT_CLAUDE/settings.json" "$HOME/.claude/settings.json" || warn "settings not linked"
sync_claude_md || warn "CLAUDE.md not written"

step "Claude Code plugins"
if confirm "Add the claude-plugins-official marketplace and install gopls-lsp?"; then
    run claude plugin marketplace add anthropics/claude-plugins-official \
        || warn "marketplace add failed (already added?)"
    run claude plugin install gopls-lsp@claude-plugins-official \
        || warn "gopls-lsp install failed"
fi

step "Claude Code MCP servers"
say "each server asks for its URL and token; leave the URL empty to skip it"
for server in Personal Soko Soundstack jira-soko; do
    mcp_server "$server"
done
