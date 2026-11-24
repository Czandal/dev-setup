#!/usr/bin/env bash
# desc: PipeWire + WirePlumber switching sample rate to match the track
. "$(dirname "$0")/lib.sh" "$@"

# Every rate your DAC supports; PipeWire switches between them instead of resampling.
RATES="${RATES:-44100 48000 88200 96000}"

step "PipeWire"
if installed pulseaudio; then
    warn "pulseaudio is installed: the package manager will ask to replace it with pipewire-pulse"
fi
pkg "pipewire pipewire-pulse pipewire-alsa wireplumber" "pipewire-audio wireplumber" || true

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
if systemctl --user is-active --quiet pulseaudio.service pulseaudio.socket 2>/dev/null || [ "$DRY_RUN" = 1 ]; then
    confirm "Stop and disable the PulseAudio daemon (audio drops for a moment)?" \
        && run systemctl --user disable --now pulseaudio.service pulseaudio.socket || true
fi
if confirm "Enable and restart pipewire, pipewire-pulse and wireplumber?"; then
    run systemctl --user enable pipewire.socket pipewire-pulse.socket wireplumber.service
    run systemctl --user restart pipewire.service pipewire-pulse.service wireplumber.service
fi

say "check: pactl info | grep 'Server Name'   -> PulseAudio (on PipeWire ...)"
say "rate in use while something plays: pw-top"
exit 0
