#!/usr/bin/env bash
# desc: mise (node, python, go, zig, lua) locked down; no tools unless --tools
. "$(dirname "$0")/lib.sh" "$@"

# The toolchain this repo is used with. zls has to match the zig minor version.
TOOLS=(node@24.3.0 python@3.13.1 go@1.24.2 zig@0.17.1 zls@0.17.0 lua@5.1.5)

step "mise"
if have mise; then
    say "already installed: $(mise --version 2>/dev/null | head -1)"
elif [ "$PM" = apt ]; then
    if confirm "Enable the mise apt repository through extrepo and install mise (sudo)?"; then
        run sudo apt-get install -y extrepo
        run sudo extrepo enable mise
        run sudo apt-get update
        run sudo apt-get install -y mise
    fi
else
    pkg mise || true
fi
if ! have mise && [ "$DRY_RUN" != 1 ]; then
    warn "mise is not installed, see https://mise.jdx.dev/installing-mise.html"
    exit 1
fi

step "Paranoid settings"
# paranoid: every project config, env file and idiomatic version file (.nvmrc...)
#   needs `mise trust`, again after each edit; unregistered plugins are refused;
#   provenance is re-verified on every install.
# auto_install=false: nothing gets installed just because a command, a task or a
#   repo asks (it also switches off exec/not_found/task auto-install).
while read -r key value; do
    if [ "$DRY_RUN" != 1 ] && [ "$(mise settings get "$key" 2>/dev/null)" = "$value" ]; then
        say "ok: $key = $value"
    else
        run mise settings set "$key" "$value"
    fi
done <<'EOF'
paranoid true
auto_install false
EOF

step "Shell"
rc_block "$HOME/.zshrc" mise 'command -v mise >/dev/null && eval "$(mise activate zsh)"' || true

step "Tools"
case " ${ARGS[*]:-} " in
    *" --tools "*)
        # lua is compiled from source
        pkg "gcc make readline" "build-essential libreadline-dev" || true
        run mise use -g "${TOOLS[@]}"
        ;;
    *)
        say "none installed. For the set this repo is used with:"
        say "  mise use -g ${TOOLS[*]}"
        ;;
esac

for old in .volta .pyenv .luaver; do
    [ -d "$HOME/$old" ] && say "replaced by mise, remove when migrated: ~/$old (and its lines in ~/.zshrc)"
done
exit 0
