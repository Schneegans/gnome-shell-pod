#!/bin/bash

# -------------------------------------------------------------------------------------- #
# This is a little helper script which copies the environment of the bash process of the #
# gnomeshell user. For many applications the environment variables like DISPLAY,         #
# DBUS_SESSION_BUS_ADDRESS, or XDG_RUNTIME_DIR are required. While you set them all with #
# a corresponding --env for podman exec, using this script is more convenient.           #
#                                                                                        #
# You can explore the effect with:                                                       #
# podman exec --user gnomeshell $(podman ps -q -n 1) env                                 #
# podman exec --user gnomeshell $(podman ps -q -n 1) /home/gnomeshell/set-env.sh env     #
# -------------------------------------------------------------------------------------- #

# Exit on error.
set -e

export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u)/bus

# Run the given command.
exec "$@"