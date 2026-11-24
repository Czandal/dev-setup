#!/usr/bin/env bash
# desc: zsh, oh-my-zsh, autosuggestions, syntax highlighting
. "$(dirname "$0")/lib.sh" "$@"

step "zsh + plugins"
have zsh || pkg zsh || true
pkg "zsh-autosuggestions zsh-syntax-highlighting" || true

step "oh-my-zsh"
if [ -d "$HOME/.oh-my-zsh" ]; then
    say "already installed: ~/.oh-my-zsh"
elif confirm "Run the oh-my-zsh installer (keeps your ~/.zshrc)?"; then
    run sh -c 'curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh | KEEP_ZSHRC=yes RUNZSH=no CHSH=no sh'
fi

step "~/.zshrc"
if [ -f "$HOME/.zshrc" ] && grep -v 'dev-setup' "$HOME/.zshrc" | grep -q 'oh-my-zsh.sh' \
    && ! grep -q '^# >>> dev-setup:zsh >>>' "$HOME/.zshrc"; then
    say "~/.zshrc already loads oh-my-zsh on its own, leaving it alone"
else
    # shellcheck disable=SC2016
    rc_block "$HOME/.zshrc" zsh 'export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="agnoster" # "avit" works without powerline fonts
plugins=(git)
source "$ZSH/oh-my-zsh.sh"
for p in zsh-autosuggestions zsh-syntax-highlighting; do
    for d in /usr/share/zsh/plugins/$p /usr/share/$p; do
        [ -r "$d/$p.zsh" ] && source "$d/$p.zsh" && break
    done
done' || true
fi

step "Default shell"
if [ "$(basename "${SHELL:-}")" = zsh ]; then
    say "already zsh"
elif have zsh && confirm "Make zsh the login shell (chsh)?"; then
    run chsh -s "$(command -v zsh)"
fi
exit 0
