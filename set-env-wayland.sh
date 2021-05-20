#!/bin/bash

set -e

export DBUS_SESSION_BUS_ADDRESS=$(cat ~/wayland-dbus-address)

exec "$@"