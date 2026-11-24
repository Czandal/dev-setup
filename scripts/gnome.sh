#!/usr/bin/env bash
# desc: GNOME on Arch: ptyxis terminal, debtap, extensions to install
. "$(dirname "$0")/lib.sh" "$@"

if [ "$PM" != pacman ]; then
    say "gnome: Arch only, nothing to do here"
    exit 0
fi

step "Terminal"
pkg ptyxis || true

step "debtap (turn a .deb into an Arch package)"
if aur debtap && confirm "Update the debtap database (sudo debtap -U)?"; then
    run sudo debtap -U
fi

step "Extensions (install from https://extensions.gnome.org)"
say "Clipboard History"
say "Extension List"
say "Search Light (configure it!!!)"
say "System Monitor"
exit 0
