#!/usr/bin/env bash
# desc: SONE, a TIDAL client that plays every track at its own sample rate
. "$(dirname "$0")/lib.sh" "$@"

# Tidal Hifi and the web player run on Chromium, which resamples everything to
# one fixed rate (48 kHz here), so PipeWire never sees the track's rate and the
# DAC never switches. SONE is native and hands PipeWire the track's own rate;
# with the allowed rates from ./setup audio the DAC follows each track. Its
# exclusive ALSA mode skips PipeWire altogether (bit-perfect, but the DAC is
# then busy for other apps while it plays).
APP=io.github.lullabyX.sone

flatpak_has() { have flatpak && flatpak info "$APP" >/dev/null 2>&1; }

step "SONE"
if have sone; then
    say "already installed: sone"
elif flatpak_has; then
    say "already installed: $APP (Flatpak)"
elif [ "$PM" = pacman ] && { have yay || have paru; }; then
    # Not sandboxed, so exclusive ALSA works without extra permissions.
    aur sone-bin || true
elif have flatpak; then
    confirm "Install $APP from Flathub (user install)?" \
        && run flatpak install --user -y flathub "$APP" || true
else
    warn "no AUR helper or flatpak, get a package from https://github.com/lullabyX/sone/releases"
fi

# The Flatpak only gets the PulseAudio socket; exclusive ALSA needs /dev/snd.
if flatpak_has; then
    if flatpak override --user --show "$APP" 2>/dev/null | grep -q '^devices=.*all'; then
        say "Flatpak already has device access (exclusive ALSA mode)"
    elif confirm "Give the SONE Flatpak access to devices (needed for exclusive ALSA mode)?"; then
        run flatpak override --user --device=all "$APP"
    fi
fi

step "Sample rates"
rates="$HOME/.config/pipewire/pipewire.conf.d/10-rates.conf"
if [ -f "$rates" ]; then
    say "PipeWire allowed rates: $(sed -n 's/.*allowed-rates = \[ *\(.*\) *\]/\1/p' "$rates")"
else
    warn "no $rates: run ./setup audio first, or PipeWire resamples everything to 48 kHz"
fi

if installed tidal-hifi || installed tidal-hifi-bin || installed tidal-hifi-git; then
    say "tidal-hifi is still installed; it always plays at 48 kHz, remove it when SONE works for you"
fi
say "log in: Get Login Code, approve on link.tidal.com; set streaming quality to Max"
say "check while it plays: pw-top (RATE column of the DAC follows the track)"
say "untouched samples: exclusive ALSA mode on the DAC's hw device (not 'default'/'pipewire',"
say "  which go back through PipeWire); other apps go silent on that DAC while SONE plays"
say "through PipeWire, keep SONE and the system volume at 100% (change volume on the DAC) and"
say "  nothing else playing, or PipeWire resamples SONE to the other stream's rate"
exit 0
