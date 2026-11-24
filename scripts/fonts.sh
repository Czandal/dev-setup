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
[ "$bad" = 0 ] || warn "some fonts are missing, see above"
exit 0
