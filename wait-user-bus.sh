#!/bin/bash

set -ex

busctl --system --watch-bind=true status >/dev/null
systemctl is-system-running --wait
busctl --user --watch-bind=true status >/dev/null
