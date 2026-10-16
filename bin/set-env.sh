#!/usr/bin/env bash

set -o errexit
set -o nounset

# Required for Wayland and D-Bus in headless session.
XDG_RUNTIME_DIR="/run/user/$(id -u)"
export XDG_RUNTIME_DIR
export DBUS_SESSION_BUS_ADDRESS="unix:path=${XDG_RUNTIME_DIR}/bus"
export WAYLAND_DISPLAY="wayland-0"
export XDG_CURRENT_DESKTOP="GNOME"
export DESKTOP_SESSION="gnome"
export GTK_A11Y="none"
export NO_AT_BRIDGE="1"

# Also set DISPLAY for Xwayland applications if available.
if [ -z "${DISPLAY:-}" ] && [ -e /tmp/.X11-unix/X0 ]; then
  export DISPLAY=:0
fi

exec "$@"
