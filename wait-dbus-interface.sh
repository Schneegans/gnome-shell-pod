#!/bin/bash

set -e

usage() {
    >&2 echo "Usage: $0 -d destination -o object_path -i interface -t timeout"
}

DESTINATION=
OBJECT_PATH=
INTERFACE=
TIMEOUT=

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

if [[ -z "${DESTINATION}" ]] || [[ -z "${OBJECT_PATH}" ]] || [[ -z "${INTERFACE}" ]] || [[ -z "${TIMEOUT}" ]]; then
    usage
    exit 1
fi

for (( elapsed=0; elapsed<TIMEOUT; elapsed++ )); do
    line_count="$(busctl introspect --user "${DESTINATION}" "${OBJECT_PATH}" "${INTERFACE}" | wc -l)"
    if (( line_count > 1 )); then
        exit 0
    fi
    sleep 1
done

>&2 echo "Timed out"
exit 1
