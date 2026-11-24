#!/usr/bin/env bash
# desc: docker, aws cli, amdgpu_top, git-who, vesktop (asked one by one)
. "$(dirname "$0")/lib.sh" "$@"

step "Docker"
if pkg "docker docker-compose docker-buildx" "docker.io"; then
    [ "$PM" = apt ] && say "compose plugin for apt: https://docs.docker.com/compose/install/linux/"
    if ! systemctl is-enabled --quiet docker 2>/dev/null && confirm "Start docker now and on boot (sudo)?"; then
        run sudo systemctl enable --now docker
    fi
    if ! id -nG | grep -qw docker && confirm "Add $USER to the docker group (root-equivalent access)?"; then
        run sudo usermod -aG docker "$USER"
        say "log out and back in for the group to apply"
    fi
fi

step "AWS CLI"
if have aws; then
    say "already installed: aws"
elif [ "$PM" = pacman ]; then
    pkg aws-cli-v2 || true
elif confirm "Install AWS CLI v2 from the official zip (sudo)?"; then
    tmp="$(mktemp -d)"
    run curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-$(uname -m).zip" -o "$tmp/aws.zip"
    run unzip -q "$tmp/aws.zip" -d "$tmp"
    run sudo "$tmp/aws/install"
    rm -rf "$tmp"
fi

step "AMD GPU stats"
have amdgpu_top && say "already installed: amdgpu_top" \
    || pkg amdgpu_top - \
    || say "skipped (other distros: https://github.com/Umio-Yasuno/amdgpu_top/releases)"

step "git-who (who wrote this repo)"
if have git-who; then
    say "already installed: git-who"
elif have go; then
    confirm "go install git-who?" && run go install github.com/sinclairtarget/git-who@latest
    say "needs \$(go env GOPATH)/bin on PATH"
elif ! aur git-who-bin; then
    say "needs go: ./setup mise, then rerun"
fi

step "Vesktop (Discord)"
have vesktop && say "already installed: vesktop" \
    || aur vesktop-bin \
    || say "skipped (other distros: https://github.com/Vencord/Vesktop/releases)"
exit 0
