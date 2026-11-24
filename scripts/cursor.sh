#!/usr/bin/env bash
# desc: Cursor: editor settings and MCP servers
. "$(dirname "$0")/lib.sh" "$@"

MCP_FILE="$HOME/.cursor/mcp.json"

# cursor_mcp_add <name> -- asks for a URL and an optional token (empty = none)
# and merges the server into ~/.cursor/mcp.json. Secrets go through the
# environment, never argv, and are never written to this repo.
cursor_mcp_add() {
    local name="$1" url token
    if [ -f "$MCP_FILE" ] && grep -q "\"$name\"" "$MCP_FILE"; then
        say "already in mcp.json: $name"
        return 0
    fi
    confirm "Add MCP server $name?" || return 0
    if [ "$DRY_RUN" = 1 ]; then
        say "would ask for the URL and token of $name"
        return 0
    fi
    read -r -p "   URL for $name (empty to skip): " url || url=""
    [ -n "$url" ] || return 0
    read -rs -p "   token for $name (empty for none): " token || token=""
    echo
    say "merging $name into $MCP_FILE"
    MCP_FILE="$MCP_FILE" MCP_NAME="$name" MCP_URL="$url" MCP_TOKEN="$token" python3 - <<'PY'
import json, os, pathlib

path = pathlib.Path(os.environ["MCP_FILE"])
data = json.loads(path.read_text()) if path.exists() else {}
entry = {"url": os.environ["MCP_URL"]}
if os.environ["MCP_TOKEN"]:
    entry["headers"] = {"Authorization": "Bearer " + os.environ["MCP_TOKEN"]}
data.setdefault("mcpServers", {})[os.environ["MCP_NAME"]] = entry
path.parent.mkdir(parents=True, exist_ok=True)
tmp = path.with_name(path.name + ".tmp")
tmp.write_text(json.dumps(data, indent=2) + "\n")
os.chmod(tmp, 0o600)
os.replace(tmp, path)
PY
}

step "Cursor"
if have cursor; then
    say "already installed: $(command -v cursor)"
elif [ "$PM" = pacman ]; then
    aur cursor-bin || warn "install cursor-bin yourself (AUR)"
else
    warn "install Cursor yourself: https://cursor.com/download"
fi

step "Cursor settings"
link "$ROOT/cursor/settings.json" "$HOME/.config/Cursor/User/settings.json" \
    || warn "settings not linked"

step "Cursor MCP servers"
if ! have python3; then
    warn "python3 is needed to merge mcp.json, skipping MCP servers"
elif confirm "Add MCP servers to $MCP_FILE? (an existing file is backed up first)"; then
    if [ -f "$MCP_FILE" ]; then
        run cp -p "$MCP_FILE" "$MCP_FILE.bak.$(date +%Y%m%d%H%M%S)"
    fi
    say "each server asks for its URL and token; leave the URL empty to skip it"
    for server in trello Personal Soko Soundstack Maumao; do
        cursor_mcp_add "$server"
    done
fi
