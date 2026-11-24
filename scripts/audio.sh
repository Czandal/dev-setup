#!/usr/bin/env bash
# desc: PipeWire + WirePlumber switching sample rate to match the track
. "$(dirname "$0")/lib.sh" "$@"

# Every rate your DAC supports; PipeWire switches between them instead of resampling.
RATES="${RATES:-44100 48000 88200 96000 176400 192000}"

step "PipeWire"
if installed pulseaudio; then
    warn "pulseaudio is installed: the package manager will ask to replace it with pipewire-pulse"
    # pulseaudio-bluetooth, -jack, ... require pulseaudio itself, so pacman refuses
    # the swap while they are installed. PipeWire covers them: bluetooth is in
    # pipewire-audio, JACK in pipewire-jack, ALSA in pipewire-alsa.
    if [ "$PM" = pacman ]; then
        mods=$(pacman -Qq | grep '^pulseaudio-' || true)
        if [ -n "$mods" ]; then
            warn "these PulseAudio modules block the swap: $(echo $mods)"
            if confirm "Remove $(echo $mods) with pacman (sudo)?"; then
                # shellcheck disable=SC2086
                run sudo pacman -R $mods || true
            fi
            if grep -qx pulseaudio-jack <<<"$mods"; then
                say "JACK apps: pipewire-jack takes over from jack2 (pacman -S pipewire-jack)"
            fi
        fi
    fi
fi
pkg "pipewire pipewire-pulse pipewire-alsa pipewire-audio wireplumber" "pipewire-audio wireplumber" || true

step "Old configs"
# A full pipewire.conf in /etc or ~/.config replaces the packaged one wholesale:
# it misses upstream changes and old ones start their own wireplumber through
# context.exec, which then fights wireplumber.service and no device shows up.
# Drop-ins in pipewire.conf.d are the supported way to change settings.
for old in /etc/pipewire/pipewire.conf "$HOME/.config/pipewire/pipewire.conf"; do
    [ -f "$old" ] || continue
    [ "$PM" = pacman ] && pacman -Qoq "$old" >/dev/null 2>&1 && continue
    warn "$old overrides the packaged PipeWire config"
    if grep -q '^[[:space:]]*{[[:space:]]*path[[:space:]]*=[[:space:]]*"[^"]*wireplumber' "$old"; then
        warn "it starts wireplumber itself, a second one next to wireplumber.service"
    fi
    if confirm "Move $old to $old.bak?"; then
        case "$old" in
            /etc/*) run sudo mv "$old" "$old.bak" ;;
            *) run mv "$old" "$old.bak" ;;
        esac
    fi
done

step "Sample rates"
conf="$HOME/.config/pipewire/pipewire.conf.d/10-rates.conf"
want="context.properties = {
    default.clock.allowed-rates = [ $RATES ]
}"
if [ -f "$conf" ] && [ "$(cat "$conf")" = "$want" ]; then
    say "up to date: $conf"
elif confirm "Write $conf (rates: $RATES)?"; then
    printf ' +  write %s\n' "$conf"
    if [ "$DRY_RUN" != 1 ]; then
        mkdir -p "$(dirname "$conf")"
        printf '%s\n' "$want" >"$conf"
    fi
fi

step "Services"
if ! installed pipewire-pulse && [ "$DRY_RUN" != 1 ]; then
    warn "pipewire-pulse is not installed, leaving PulseAudio running"
    exit 1
fi
# pulseaudio enables its socket globally (/etc/systemd/user), which a user-level
# disable does not override; mask does.
if installed pulseaudio || [ "$DRY_RUN" = 1 ]; then
    confirm "Stop and mask the PulseAudio daemon (audio drops for a moment)?" \
        && run systemctl --user mask --now pulseaudio.service pulseaudio.socket || true
elif systemctl --user is-active --quiet pulseaudio.service pulseaudio.socket 2>/dev/null; then
    # Package already gone, daemon from before the swap still running.
    run systemctl --user stop pulseaudio.service pulseaudio.socket || true
fi
if confirm "Enable and restart pipewire, pipewire-pulse and wireplumber?"; then
    run systemctl --user enable pipewire.socket pipewire-pulse.socket wireplumber.service
    run systemctl --user restart pipewire.service pipewire-pulse.service wireplumber.service
fi

say "check: pactl info | grep 'Server Name'   -> PulseAudio (on PipeWire ...)"
say "rate in use while something plays: pw-top"
exit 0
