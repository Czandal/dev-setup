#!/bin/bash
# Paste output to /usr/share/applications
set -euo pipefail

echo "[Desktop Entry]"
echo "Type=Application"
echo "Encoding=UTF-8"
echo "Name=$2"
echo "Comment=$3"
echo "Icon=$4"
echo "Exec=$1"
echo "Terminal=false"
echo "Categories=$2;Application"

