#!/usr/bin/env bash
# desc: fonts: Adwaita UI, Noto generics + emoji, nerd icons, GNOME font settings
. "$(dirname "$0")/lib.sh" "$@"

step "Font packages"
# UI and terminal (GNOME 48+ default); not packaged for apt everywhere
pkg adwaita-fonts - || true
# generics, CJK, colour emoji, plus DejaVu (book code blocks) and Liberation (Arial/Times metrics)
pkg "noto-fonts noto-fonts-cjk noto-fonts-emoji ttf-dejavu ttf-liberation" \
    "fonts-noto-core fonts-noto-cjk fonts-noto-color-emoji fonts-dejavu-core fonts-liberation" || true
# icon glyphs for nvim (devicons in oil), pulled in only by cachyos-fish-config otherwise
pkg ttf-fantasque-nerd - ||
    warn "no package, put FantasqueSansMono from https://github.com/ryanoasis/nerd-fonts/releases in ~/.local/share/fonts"

step "Book and PDF fonts (nvim/md-to-pdf: book.css, style.css)"
pkg "inter-font ttf-jetbrains-mono otf-libertinus" \
    "fonts-inter fonts-jetbrains-mono fonts-libertinus" || true

# EB Garamond (Octavio Pardo, has small caps and oldstyle figures) from google/fonts,
# pinned and checksummed; the only Arch package is an orphaned 2015 AUR build.
EBG_REV=f8c1d3d6cc75e30d77130bdcbfbff27e3b6233fe
EBG_DIR="$HOME/.local/share/fonts/eb-garamond"
EBG_SUMS="ef9512f92f6d579e5dc75af59a5a4b1b8b47d2eda89e00b954d44520e5369027  EBGaramond[wght].ttf
bba2c4499c93c9612b90b9825d32b07da52fce2fe57562a1eb6b833553f93c4e  EBGaramond-Italic[wght].ttf
0985066662eb755ed3683ae5482a81a9195b49ce3f7e165cc2388b3dbece7dd7  OFL.txt"

eb_garamond() {
    local tmp f u
    if [ -d "$EBG_DIR" ] && (cd "$EBG_DIR" && sha256sum --quiet -c - <<<"$EBG_SUMS" >/dev/null 2>&1); then
        say "already installed: EB Garamond ($EBG_DIR)"
        return 0
    fi
    confirm "Download EB Garamond (google/fonts ${EBG_REV:0:7}) to $EBG_DIR?" || return 0
    printf ' +  download EB Garamond to %s\n' "$EBG_DIR"
    [ "$DRY_RUN" = 1 ] && return 0
    tmp="$(mktemp -d)"
    while read -r _ f; do
        u="${f//[/%5B}"
        curl -fsSL -o "$tmp/$f" "https://raw.githubusercontent.com/google/fonts/$EBG_REV/ofl/ebgaramond/${u//]/%5D}" || {
            rm -rf "$tmp"; warn "download failed: $f"; return 1
        }
    done <<<"$EBG_SUMS"
    (cd "$tmp" && sha256sum --quiet -c - <<<"$EBG_SUMS") || { rm -rf "$tmp"; warn "checksum mismatch, not installed"; return 1; }
    mkdir -p "$EBG_DIR"
    mv "$tmp"/* "$EBG_DIR"/
    rm -rf "$tmp"
    fc-cache -f "$EBG_DIR"
}
eb_garamond || true

step "Fontconfig (sans, serif, monospace, emoji)"
link "$ROOT/fonts/50-dev-setup.conf" "$HOME/.config/fontconfig/conf.d/50-dev-setup.conf" || true

# gset <schema> <key> <value>  -- set a GNOME key only when it differs.
gset() {
    local cur
    cur="$(gsettings get "$1" "$2" 2>/dev/null)" || { say "no $1 $2, skipped"; return 0; }
    [ "$cur" = "$3" ] && { say "already $2 = $3"; return 0; }
    confirm "Set $1 $2 to $3 (now $cur)?" || return 0
    run gsettings set "$1" "$2" "$3"
}

step "GNOME font settings"
if have gsettings && gsettings list-schemas | grep -qx org.gnome.desktop.interface; then
    gset org.gnome.desktop.interface font-name "'Adwaita Sans 11'"
    gset org.gnome.desktop.interface document-font-name "'Adwaita Sans 12'"
    gset org.gnome.desktop.interface monospace-font-name "'Adwaita Mono 11'"
    gset org.gnome.desktop.interface font-antialiasing "'grayscale'"
    gset org.gnome.desktop.interface font-hinting "'slight'"
    gset org.gnome.desktop.wm.preferences titlebar-font "'Adwaita Sans Bold 11'"
    # GNOME Console follows monospace-font-name
    gset org.gnome.Console use-system-font true
else
    say "no GNOME here, skipped"
fi

step "Check"
[ "$DRY_RUN" = 1 ] && { say "dry run, nothing to check"; exit 0; }
bad=0
expect() {
    local got
    got="$(fc-match -f '%{family[0]}' "$1")"
    if [ "$got" = "$2" ]; then say "$1 -> $got"; else warn "$1 -> $got (want $2)"; bad=1; fi
}
expect sans-serif "Noto Sans"
expect serif "Noto Serif"
expect monospace "Noto Sans Mono"
expect emoji "Noto Color Emoji"
expect "Adwaita Sans" "Adwaita Sans"
expect "Adwaita Mono" "Adwaita Mono"
expect "monospace:charset=f121" "FantasqueSansM Nerd Font Mono" # nerd icon
expect "EB Garamond" "EB Garamond"
expect "Libertinus Serif" "Libertinus Serif"
expect Inter Inter
expect "JetBrains Mono" "JetBrains Mono"
[ "$bad" = 0 ] || warn "some fonts are missing, see above"
exit 0
