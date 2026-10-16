#!/usr/bin/env bash

# ----------------------------------------------------------------------------- #
# Automated screenshot capture script for gnome-shell-pod documentation images. #
#                                                                               #
# Generates the 3 canonical preview images:                                     #
#   1. Clean desktop with top bar and default background image                  #
#   2. Desktop with GNOME Settings (gnome-control-center) opened                #
#   3. Show Applications activities overview / app grid                         #
#                                                                               #
# Usage: ./scripts/capture.sh [OPTIONS] [IMAGE_TAG] [OUTPUT_DIR]                #
# Example: ./scripts/capture.sh local/gnome-shell-pod:44 pictures               #
# ----------------------------------------------------------------------------- #

set -o errexit
set -o nounset
set -o pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd -- "${SCRIPT_DIR}/.." && pwd)

usage() {
  printf 'Usage: %s [OPTIONS] [IMAGE_TAG] [OUTPUT_DIR]\n\n' "$0"
  printf 'Arguments:\n'
  printf '  IMAGE_TAG    Container image tag to use (default: local/gnome-shell-pod:44)\n'
  printf '  OUTPUT_DIR   Host directory to save captured images (default: %s/pictures)\n\n' "${REPO_ROOT}"
  printf 'Options:\n'
  printf '  -h, --help   Show this help message\n'
}

POSITIONAL_ARGS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      printf 'Error: Unknown option: %s\n\n' "$1" >&2
      usage >&2
      exit 1
      ;;
    *)
      POSITIONAL_ARGS+=("$1")
      shift
      ;;
  esac
done

IMAGE="${POSITIONAL_ARGS[0]:-local/gnome-shell-pod:44}"
OUTPUT_DIR="${POSITIONAL_ARGS[1]:-${REPO_ROOT}/pictures}"

mkdir -p "${OUTPUT_DIR}"

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
printf 'Capturing documentation images from: %s\n' "${IMAGE}"
printf 'Output directory: %s\n' "${OUTPUT_DIR}"
printf 'Container engine: %s\n' "${CONTAINER_RUNTIME}"
printf '==============================================================\n'

POD=$(${CONTAINER_RUNTIME} run --rm "${RUN_OPTS[@]}" -td "${IMAGE}")
printf 'Container started with ID: %s\n' "${POD}"

cleanup() {
  printf '\nCleaning up container %s...\n' "${POD}"
  ${CONTAINER_RUNTIME} stop -t 3 "${POD}" 2>/dev/null || ${CONTAINER_RUNTIME} rm -f "${POD}" 2>/dev/null || true
}
trap cleanup EXIT

do_in_pod() {
  ${CONTAINER_RUNTIME} exec --user gnomeshell "${POD}" set-env.sh "$@"
}

eval_js() {
  local script="$1"
  do_in_pod gdbus call --session \
    --dest org.gnome.Shell \
    --object-path /org/gnome/Shell \
    --method org.gnome.Shell.Eval "${script}"
}

printf 'Waiting for user bus and Wayland socket...\n'
do_in_pod wait-user-bus.sh

printf 'Waiting for org.gnome.Shell.Extensions D-Bus interface...\n'
do_in_pod wait-dbus-interface.sh -d org.gnome.Shell -o /org/gnome/Shell -i org.gnome.Shell.Extensions

# Wait for GNOME Shell startup animation and initialization to complete
for i in $(seq 1 50); do
  res=$(eval_js "(async () => { const Main = await import('resource:///org/gnome/shell/ui/main.js'); return !Main.layoutManager._startingUp; })()" 2>/dev/null || true)
  if [[ "${res}" == *" 'true')"* ]]; then
    break
  fi
  sleep 0.2
done

# --- 1. Clean desktop with top bar and default background ---
printf '\n[1/3] Capturing desktop with top bar and background...\n'
eval_js "(async () => { const Main = await import('resource:///org/gnome/shell/ui/main.js'); Main.overview.hide(); })()" >/dev/null
for i in $(seq 1 30); do
  res=$(eval_js "(async () => { const Main = await import('resource:///org/gnome/shell/ui/main.js'); return !Main.overview.visible; })()" 2>/dev/null || true)
  if [[ "${res}" == *" 'true')"* ]]; then
    break
  fi
  sleep 0.2
done
sleep 0.5
do_in_pod screenshot.sh /home/gnomeshell/capture1.jpg
${CONTAINER_RUNTIME} cp "${POD}:/home/gnomeshell/capture1.jpg" "${OUTPUT_DIR}/capture1.jpg"
printf '  -> Saved %s/capture1.jpg\n' "${OUTPUT_DIR}"

# --- 2. Desktop with GNOME Settings app open ---
printf '\n[2/3] Launching GNOME Settings and capturing desktop...\n'
${CONTAINER_RUNTIME} exec -d --user gnomeshell "${POD}" set-env.sh gnome-control-center

# Wait for Settings window to appear and ensure overview is closed
settings_ready=false
for i in $(seq 1 50); do
  res=$(eval_js "global.display.list_all_windows().some(w => w.get_wm_class() === 'org.gnome.Settings' || w.get_wm_class() === 'gnome-control-center')" 2>/dev/null || true)
  if [[ "${res}" == *" 'true')"* ]]; then
    settings_ready=true
    break
  fi
  sleep 0.2
done

if [[ "${settings_ready}" != "true" ]]; then
  printf 'Warning: GNOME Settings window did not appear within 10s.\n' >&2
fi

# Ensure overview does not obscure the opened window
eval_js "(async () => { const Main = await import('resource:///org/gnome/shell/ui/main.js'); Main.overview.hide(); })()" >/dev/null
sleep 1
do_in_pod screenshot.sh /home/gnomeshell/capture2.jpg
${CONTAINER_RUNTIME} cp "${POD}:/home/gnomeshell/capture2.jpg" "${OUTPUT_DIR}/capture2.jpg"
printf '  -> Saved %s/capture2.jpg\n' "${OUTPUT_DIR}"

# Close Settings app and wait for window to disappear
${CONTAINER_RUNTIME} exec --user gnomeshell "${POD}" killall gnome-control-center 2>/dev/null || true
for i in $(seq 1 30); do
  res=$(eval_js "global.display.list_all_windows().some(w => w.get_wm_class() === 'org.gnome.Settings' || w.get_wm_class() === 'gnome-control-center')" 2>/dev/null || true)
  if [[ "${res}" != *" 'true')"* ]]; then
    break
  fi
  sleep 0.1
done
sleep 0.5

# --- 3. Show Applications activities overlay ---
printf '\n[3/3] Opening Show Applications app grid overlay...\n'
eval_js "(async () => {
  const Main = await import('resource:///org/gnome/shell/ui/main.js');
  const OverviewControls = await import('resource:///org/gnome/shell/ui/overviewControls.js');
  if (!Main.overview.visible) {
    Main.overview.show(OverviewControls.ControlsState.APP_GRID);
  }
  if (Main.overview.dash && Main.overview.dash.showAppsButton) {
    Main.overview.dash.showAppsButton.checked = true;
  }
  if (Main.overview._overview && Main.overview._overview.controls) {
    Main.overview._overview.controls._stateAdjustment.value = OverviewControls.ControlsState.APP_GRID;
  }
})()" >/dev/null
sleep 1
do_in_pod screenshot.sh /home/gnomeshell/capture3.jpg
${CONTAINER_RUNTIME} cp "${POD}:/home/gnomeshell/capture3.jpg" "${OUTPUT_DIR}/capture3.jpg"
printf '  -> Saved %s/capture3.jpg\n' "${OUTPUT_DIR}"

printf '\n==============================================================\n'
printf 'SUCCESS: All 3 images captured and saved to %s\n' "${OUTPUT_DIR}"
printf '==============================================================\n'
