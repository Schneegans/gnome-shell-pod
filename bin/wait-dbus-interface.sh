#!/usr/bin/env bash

# ------------------------------------------------------------------------------------- #
# This script waits until the given interface becomes available on the D-Bus. It can be #
# used to wait for GNOME Shell to finish starting up. Like this:                        #
#                                                                                       #
# wait-dbus-interface.sh -d org.gnome.Shell -o /org/gnome/Shell \                       #
#                        -i org.gnome.Shell.Extensions                                  #
# ------------------------------------------------------------------------------------- #

set -o errexit
set -o nounset
set -o pipefail

if [ -z "${XDG_RUNTIME_DIR:-}" ]; then
  XDG_RUNTIME_DIR="/run/user/$(id -u)"
  export XDG_RUNTIME_DIR
fi
if [ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]; then
  export DBUS_SESSION_BUS_ADDRESS="unix:path=${XDG_RUNTIME_DIR}/bus"
fi

usage() {
    printf 'Usage: %s -d destination -o object_path -i interface [-t timeout]\n' "$0" >&2
}

DESTINATION=
OBJECT_PATH=
INTERFACE=
TIMEOUT=60

while getopts "d:o:i:t:h" opt; do
    case $opt in
    d) DESTINATION="${OPTARG}";;
    o) OBJECT_PATH="${OPTARG}";;
    i) INTERFACE="${OPTARG}";;
    t) TIMEOUT="${OPTARG}";;
    h) usage; exit 0;;
    *) usage; exit 1;;
    esac
done

if [[ -z "${DESTINATION}" ]] || [[ -z "${OBJECT_PATH}" ]] || [[ -z "${INTERFACE}" ]]; then
    usage
    exit 1
fi

START_TIME=$(date +%s)
gdbus wait --session --timeout "${TIMEOUT}" "${DESTINATION}"

while : ; do
    if gdbus introspect --session -d "${DESTINATION}" -o "${OBJECT_PATH}" 2>/dev/null | grep "interface ${INTERFACE} " >/dev/null; then
        break
    fi
    CURRENT_TIME=$(date +%s)
    if (( CURRENT_TIME - START_TIME >= TIMEOUT )); then
        printf 'Error: Timed out after %ss waiting for interface %s on %s%s.\n' "${TIMEOUT}" "${INTERFACE}" "${DESTINATION}" "${OBJECT_PATH}" >&2
        exit 1
    fi
    sleep 0.2
done
