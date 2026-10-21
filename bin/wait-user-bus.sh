#!/usr/bin/env bash

# ------------------------------------------------------------------------------------ #
# This script waits until systemd and the user session bus / wayland socket are ready. #
# It includes a timeout so it will never hang indefinitely.                            #
# ------------------------------------------------------------------------------------ #

set -o errexit
set -o nounset

TIMEOUT=60
START_TIME=$(date +%s)

check_timeout() {
  local current_time
  current_time=$(date +%s)
  if (( current_time - START_TIME >= TIMEOUT )); then
    printf 'Error: Timed out after %ss waiting for %s.\n' "${TIMEOUT}" "${WAITING_FOR:-user session / Wayland socket}" >&2
    exit 1
  fi
}

UID_NUM=$(id -u)
RUNTIME_DIR="/run/user/${UID_NUM}"
export XDG_RUNTIME_DIR="${RUNTIME_DIR}"
export DBUS_SESSION_BUS_ADDRESS="unix:path=${RUNTIME_DIR}/bus"
export SYSTEMD_PAGER=cat
export PAGER=cat

WAITING_FOR="user runtime directory and bus socket (${RUNTIME_DIR}/bus)"
# 1. Wait for user runtime directory and bus socket
while [ ! -S "${RUNTIME_DIR}/bus" ]; do
  check_timeout
  sleep 0.2
done

WAITING_FOR="user session bus to respond (busctl --user)"
# 2. Wait for the user bus to respond
while ! busctl --user --no-pager status >/dev/null 2>&1; do
  check_timeout
  sleep 0.2
done

WAITING_FOR="Wayland display socket (${RUNTIME_DIR}/wayland-0)"
# 3. Wait for the Wayland socket
while [ ! -S "${RUNTIME_DIR}/wayland-0" ]; do
  check_timeout
  sleep 0.2
done

printf 'User bus and Wayland socket are ready.\n'
