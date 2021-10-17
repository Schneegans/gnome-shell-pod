#!/bin/bash

# -------------------------------------------------------------------------------------- #
# This script waits until the user and the session bus are available.                    #
# -------------------------------------------------------------------------------------- #

set -e

busctl --system --watch-bind=true status >/dev/null
systemctl is-system-running --wait >/dev/null

while ! busctl --user --watch-bind=true status >/dev/null; do
    sleep 0.1
done
