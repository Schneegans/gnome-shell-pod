#!/usr/bin/env bash

# --------------------------------------------------------------------------------- #
# This script captures a screenshot of the running GNOME Shell headless session via #
# the org.gnome.Shell.Screenshot D-Bus API. Supports PNG (.png) and JPEG (.jpg).    #
#                                                                                   #
# Usage: screenshot.sh [output_path.png|output_path.jpg]                            #
# --------------------------------------------------------------------------------- #

set -o errexit
set -o nounset

OUTPUT="${1:-/home/gnomeshell/capture.jpg}"

if [ -z "${XDG_RUNTIME_DIR:-}" ]; then
  XDG_RUNTIME_DIR="/run/user/$(id -u)"
  export XDG_RUNTIME_DIR
fi
if [ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]; then
  export DBUS_SESSION_BUS_ADDRESS="unix:path=${XDG_RUNTIME_DIR}/bus"
fi

if [[ "${OUTPUT}" =~ \.jpe?g$ ]]; then
  TMP_PNG="${OUTPUT}.tmp.png"
  gdbus call --session \
      --dest org.gnome.Shell \
      --object-path /org/gnome/Shell/Screenshot \
      --method org.gnome.Shell.Screenshot.Screenshot false false "${TMP_PNG}" >/dev/null

  gm convert "${TMP_PNG}" -quality 85 "${OUTPUT}"
  rm -f "${TMP_PNG}"
else
  gdbus call --session \
      --dest org.gnome.Shell \
      --object-path /org/gnome/Shell/Screenshot \
      --method org.gnome.Shell.Screenshot.Screenshot false false "${OUTPUT}" >/dev/null
fi

printf '%s\n' "${OUTPUT}"
