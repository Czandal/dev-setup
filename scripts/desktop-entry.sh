#!/usr/bin/env bash
# Make a program show up in the app launcher.
# Usage: desktop-entry.sh <exec> <name> [comment] [icon]
set -euo pipefail

[ $# -ge 2 ] || { sed -n '2,3s/^# //p' "$0" >&2; exit 1; }

dir="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
file="$dir/$(printf '%s' "$2" | tr '[:upper:] ' '[:lower:]-' | tr -cd 'a-z0-9._-').desktop"
mkdir -p "$dir"
cat >"$file" <<ENTRY
[Desktop Entry]
Type=Application
Name=$2
Comment=${3:-}
Icon=${4:-}
Exec=$1
Terminal=false
Categories=Utility;
ENTRY
echo "$file"
