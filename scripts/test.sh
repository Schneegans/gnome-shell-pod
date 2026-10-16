#!/usr/bin/env bash

# ------------------------------------------------------------- #
# End-to-end validation test script for gnome-shell-pod images. #
#                                                               #
# Usage: ./scripts/test.sh [IMAGE_TAG]                          #
# Example: ./scripts/test.sh local/gnome-shell-pod:44           #
# ------------------------------------------------------------- #

set -o errexit
set -o nounset
set -o pipefail

IMAGE="${1:-local/gnome-shell-pod:44}"

# Determine container runtime (podman or docker)
if [[ -z "${CONTAINER_RUNTIME:-}" ]]; then
  if command -v docker >/dev/null 2>&1 && docker image inspect "${IMAGE}" >/dev/null 2>&1; then
    CONTAINER_RUNTIME="docker"
  elif command -v podman >/dev/null 2>&1 && podman image exists "${IMAGE}" 2>/dev/null; then
    CONTAINER_RUNTIME="podman"
  elif command -v podman >/dev/null 2>&1; then
    CONTAINER_RUNTIME="podman"
  elif command -v docker >/dev/null 2>&1; then
    CONTAINER_RUNTIME="docker"
  else
    printf 'Error: Neither podman nor docker was found in PATH.\n' >&2
    exit 1
  fi
fi

if [[ "${CONTAINER_RUNTIME}" == "podman" ]]; then
  RUN_OPTS=(--systemd=always --cap-add=SYS_NICE --cap-add=IPC_LOCK --cap-add=CAP_SYS_ADMIN)
elif [[ "${CONTAINER_RUNTIME}" == "docker" ]]; then
  RUN_OPTS=(--privileged)
else
  printf 'Error: Unsupported CONTAINER_RUNTIME: %s\n' "${CONTAINER_RUNTIME}" >&2
  exit 1
fi

printf '==============================================================\n'
printf 'Testing container image: %s (using %s)\n' "${IMAGE}" "${CONTAINER_RUNTIME}"
printf '==============================================================\n'

POD=$(${CONTAINER_RUNTIME} run --rm "${RUN_OPTS[@]}" -td "${IMAGE}")
printf 'Container started with ID: %s\n' "${POD}"

cleanup() {
  printf 'Cleaning up container %s...\n' "${POD}"
  ${CONTAINER_RUNTIME} stop -t 3 "${POD}" 2>/dev/null || ${CONTAINER_RUNTIME} rm -f "${POD}" 2>/dev/null || true
}
trap cleanup EXIT

printf '1. Waiting for user bus and Wayland socket...\n'
${CONTAINER_RUNTIME} exec --user gnomeshell "${POD}" set-env.sh wait-user-bus.sh

printf '2. Waiting for org.gnome.Shell.Extensions D-Bus interface...\n'
${CONTAINER_RUNTIME} exec --user gnomeshell "${POD}" set-env.sh wait-dbus-interface.sh -d org.gnome.Shell -o /org/gnome/Shell -i org.gnome.Shell.Extensions

printf '3. Capturing screenshot...\n'
sleep 1
${CONTAINER_RUNTIME} exec --user gnomeshell "${POD}" set-env.sh screenshot.sh /home/gnomeshell/ci-test.png
for _ in {1..10}; do
  if ${CONTAINER_RUNTIME} exec "${POD}" test -f /home/gnomeshell/ci-test.png 2>/dev/null; then
    break
  fi
  sleep 0.5
done
${CONTAINER_RUNTIME} cp "${POD}:/home/gnomeshell/ci-test.png" /tmp/ci-test.png
file /tmp/ci-test.png

printf '4. Testing JavaScript evaluation via org.gnome.Shell.Eval...\n'
EVAL_OUT=$(${CONTAINER_RUNTIME} exec --user gnomeshell "${POD}" set-env.sh gdbus call --session --dest org.gnome.Shell --object-path /org/gnome/Shell --method org.gnome.Shell.Eval "1900 + 126")
printf 'Eval output: %s\n' "${EVAL_OUT}"
if [[ "${EVAL_OUT}" != *"'2026'"* ]]; then
  printf 'Error: Eval failed or did not return expected calculation.\n' >&2
  exit 1
fi

printf '5. Installing test extension...\n'
# This is going to be brittle and eventually will break when the shell version moves on too far
${CONTAINER_RUNTIME} exec --user gnomeshell "${POD}" bash -c "
EXT_DIR=~/.local/share/gnome-shell/extensions/test-wayland@example.com
mkdir -p \"\$EXT_DIR\"
cat << 'EOF' > \"\$EXT_DIR/metadata.json\"
{
  \"uuid\": \"test-wayland@example.com\",
  \"name\": \"Test Wayland Extension\",
  \"description\": \"Wayland verification test extension\",
  \"shell-version\": [\"47\", \"48\", \"49\", \"50\", \"51\", \"52\"]
}
EOF
cat << 'EOF' > \"\$EXT_DIR/extension.js\"
import { Extension } from \"resource:///org/gnome/shell/extensions/extension.js\";
export default class TestWaylandExtension extends Extension {
    enable() {
        console.log(\"GNOME_SHELL_POD_TEST_EXTENSION_ENABLED\");
    }
    disable() {
        console.log(\"GNOME_SHELL_POD_TEST_EXTENSION_DISABLED\");
    }
}
EOF
"

printf '6. Reloading extensions...\n'
${CONTAINER_RUNTIME} exec --user gnomeshell "${POD}" set-env.sh reload-extensions.sh

printf '7. Enabling test extension...\n'
${CONTAINER_RUNTIME} exec --user gnomeshell "${POD}" set-env.sh gnome-extensions enable test-wayland@example.com

printf '8. Checking extension info...\n'
INFO_OUT=$(${CONTAINER_RUNTIME} exec --user gnomeshell "${POD}" set-env.sh gnome-extensions info test-wayland@example.com)
printf '%s\n' "${INFO_OUT}"
if [[ "${INFO_OUT}" != *"State: ACTIVE"* ]]; then
  printf 'Error: Extension is not in State: ACTIVE\n' >&2
  exit 1
fi

printf '9. Verifying extension activation in journalctl...\n'
FOUND=0
for i in {1..10}; do
  if ${CONTAINER_RUNTIME} exec --user gnomeshell "${POD}" journalctl --user _COMM=gnome-shell --no-pager 2>/dev/null | grep -q "GNOME_SHELL_POD_TEST_EXTENSION_ENABLED"; then
    FOUND=1
    break
  fi
  sleep 0.5
done

if (( FOUND == 0 )); then
  printf 'Error: Extension enable message not found in journalctl logs.\n' >&2
  exit 1
fi

printf 'Extension activation log confirmed in journalctl!\n'
printf '==============================================================\n'
printf 'SUCCESS: Image %s passed all verification tests!\n' "${IMAGE}"
printf '==============================================================\n'
