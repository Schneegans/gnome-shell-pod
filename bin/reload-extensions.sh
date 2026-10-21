#!/usr/bin/env bash

# ---------------------------------------------------------------------------- #
# This script asks the running GNOME Shell to re-scan and load newly installed #
# extensions from ~/.local/share/gnome-shell/extensions.                       #
# ---------------------------------------------------------------------------- #

set -o errexit
set -o nounset

if [ -z "${XDG_RUNTIME_DIR:-}" ]; then
  XDG_RUNTIME_DIR="/run/user/$(id -u)"
  export XDG_RUNTIME_DIR
fi
if [ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]; then
  export DBUS_SESSION_BUS_ADDRESS="unix:path=${XDG_RUNTIME_DIR}/bus"
fi

gdbus call --session \
    --dest org.gnome.Shell \
    --object-path /org/gnome/Shell \
    --method org.gnome.Shell.Eval \
    "(async () => { const Main = await import('resource:///org/gnome/shell/ui/main.js'); await Main.extensionManager._loadExtensions(); })()" >/dev/null
