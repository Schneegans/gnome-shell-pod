#!/bin/bash

set -e

busctl --system --watch-bind=true status >/dev/null
systemctl is-system-running --wait >/dev/null

while ! busctl --user --watch-bind=true status >/dev/null; do
    sleep 0.1
done
