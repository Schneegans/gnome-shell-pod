#!/bin/bash

set -e

echo $DBUS_SESSION_BUS_ADDRESS > ~/wayland-dbus-address

export MUTTER_DEBUG_DUMMY_MODE_SPECS=1920x1080@60.0
exec gnome-shell --nested --wayland
