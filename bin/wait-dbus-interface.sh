#!/bin/bash

# -------------------------------------------------------------------------------------- #
# This script waits until the given interface becomes available on the D-Bus. It can be  #
# used to wait for GNOME Shell to finish starting up. Like this:                         #
#                                                                                        #
# wait-dbus-interface.sh -d org.gnome.Shell -o /org/gnome/Shell \                        #
#                        -i org.gnome.Shell.Extensions                                   #
# -------------------------------------------------------------------------------------- #

set -e

usage() {
    >&2 echo "Usage: $0 -d destination -o object_path -i interface"
}

DESTINATION=
OBJECT_PATH=
INTERFACE=

while getopts "d:o:i:h" opt; do
    case $opt in
    d) DESTINATION="${OPTARG}";;
    o) OBJECT_PATH="${OPTARG}";;
    i) INTERFACE="${OPTARG}";;
    h) usage; exit 0;;
    *) usage; exit 1;;
    esac
done

if [[ -z "${DESTINATION}" ]] || [[ -z "${OBJECT_PATH}" ]] || [[ -z "${INTERFACE}" ]]; then
    usage
    exit 1
fi

gdbus wait --session "${DESTINATION}"

while : ; do
    if gdbus introspect --session -d "${DESTINATION}" -o "${OBJECT_PATH}" | grep "interface ${INTERFACE} " >/dev/null; then
        break
    elif (( PIPESTATUS[0] )); then
        exit "${PIPESTATUS[0]}"
    fi
    sleep 0.1
done
