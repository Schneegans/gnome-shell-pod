#!/bin/bash

# Required to use the D-Bus.
export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u)/bus

# Required for things like xdotool.
export DISPLAY=:99

eval "$@"
