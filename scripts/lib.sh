#!/usr/bin/env bash
# Shared helpers for the setup scripts. Source it: `. "$(dirname "$0")/lib.sh" "$@"`
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DRY_RUN="${DRY_RUN:-0}"
ASSUME_YES="${ASSUME_YES:-0}"
ARGS=()
for arg in "$@"; do
    case "$arg" in
        -n | --dry-run) DRY_RUN=1 ;;
        -y | --yes) ASSUME_YES=1 ;;
        *) ARGS+=("$arg") ;;
    esac
done
export DRY_RUN ASSUME_YES

if command -v pacman >/dev/null; then
    PM=pacman
elif command -v apt-get >/dev/null; then
    PM=apt
else
    PM=none
fi

step() { printf '\n\033[1m== %s\033[0m\n' "$*"; }
say() { printf '   %s\n' "$*"; }
warn() { printf '\033[33m !  %s\033[0m\n' "$*" >&2; }
have() { command -v "$1" >/dev/null 2>&1; }

# Print the command, run it unless --dry-run.
run() {
    printf ' +  %s\n' "$*"
    [ "$DRY_RUN" = 1 ] || "$@"
}

# Ask before anything that touches the system. --dry-run and --yes answer yes;
# without a terminal the answer is no.
confirm() {
    [ "$DRY_RUN" = 1 ] || [ "$ASSUME_YES" = 1 ] && return 0
    [ -t 0 ] || { warn "no terminal, skipping: $1"; return 1; }
    local reply
    read -r -p " ?  $1 [y/N] " reply
    [[ "$reply" =~ ^[Yy] ]]
}

installed() {
    case "$PM" in
        pacman) pacman -Qq "$1" >/dev/null 2>&1 ;;
        apt) dpkg -s "$1" >/dev/null 2>&1 ;;
        *) return 1 ;;
    esac
}

# pkg "<pacman names>" ["<apt names>"]  -- apt names default to the pacman ones,
# "-" means not packaged for apt. Returns 1 when nothing could be installed.
pkg() {
    local names missing=() p
    case "$PM" in
        pacman) names="$1" ;;
        apt) names="${2:-$1}" ;;
        *) warn "no pacman/apt here, install yourself: $1"; return 1 ;;
    esac
    [ "$names" = "-" ] && return 1
    for p in $names; do installed "$p" || missing+=("$p"); done
    [ ${#missing[@]} -eq 0 ] && { say "already installed: $names"; return 0; }
    confirm "Install ${missing[*]} with $PM (sudo)?" || return 1
    if [ "$PM" = pacman ]; then
        run sudo pacman -S --needed "${missing[@]}"
    else
        run sudo apt-get install -y "${missing[@]}"
    fi
}

# aur <names...>  -- Arch only, through yay or paru, never with sudo.
aur() {
    local helper="" h p missing=()
    [ "$PM" = pacman ] || return 1
    for h in yay paru; do have "$h" && { helper=$h; break; }; done
    [ -n "$helper" ] || { warn "no AUR helper (yay/paru), install yourself: $*"; return 1; }
    for p in "$@"; do installed "$p" || missing+=("$p"); done
    [ ${#missing[@]} -eq 0 ] && { say "already installed: $*"; return 0; }
    confirm "Install ${missing[*]} from AUR with $helper?" || return 1
    run "$helper" -S --needed "${missing[@]}"
}

# link <source> <target>  -- symlink, moving whatever is in the way to a backup.
link() {
    local src="$1" dst="$2" bak
    if [ "$(readlink -f "$dst" 2>/dev/null)" = "$(readlink -f "$src")" ]; then
        say "already linked: $dst"
        return 0
    fi
    confirm "Link $dst -> $src?" || return 1
    if [ -e "$dst" ] || [ -L "$dst" ]; then
        bak="$dst.bak.$(date +%Y%m%d%H%M%S)"
        run mv "$dst" "$bak"
    fi
    run mkdir -p "$(dirname "$dst")"
    run ln -s "$src" "$dst"
}

# rc_block <file> <name> <content>  -- keep one marked block per name in a file;
# rerunning rewrites the block where it is instead of appending another.
rc_block() {
    local file="$1" name="$2" tmp
    local open="# >>> dev-setup:$name >>>" close="# <<< dev-setup:$name <<<"
    local block="$open"$'\n'"$3"$'\n'"$close"
    tmp="$(mktemp)"
    if [ -f "$file" ] && grep -qxF "$open" "$file"; then
        BLOCK="$block" awk -v o="$open" -v c="$close" \
            '$0==o{print ENVIRON["BLOCK"]; skip=1} !skip{print} $0==c{skip=0}' "$file" >"$tmp"
    else
        [ -s "$file" ] && { cat "$file"; echo; } >"$tmp"
        printf '%s\n' "$block" >>"$tmp"
    fi
    if [ -f "$file" ] && cmp -s "$tmp" "$file"; then
        say "up to date: $file ($name)"
        rm -f "$tmp"
        return 0
    fi
    if ! confirm "Write the dev-setup:$name block to $file?"; then
        rm -f "$tmp"
        return 1
    fi
    printf ' +  update %s (block %s)\n' "$file" "$name"
    if [ "$DRY_RUN" != 1 ]; then
        mkdir -p "$(dirname "$file")"
        cat "$tmp" >"$file"
    fi
    rm -f "$tmp"
}
