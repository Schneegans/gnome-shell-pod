#!/usr/bin/env bash

# -------------------------------------------------------------- #
# Build container images locally using Podman or Docker.         #
#                                                                #
# Usage: ./scripts/build.sh [VERSION] [OPTIONS]                  #
#                                                                #
# Arguments:                                                     #
#   VERSION          Fedora version to build (e.g. 41, 42, 43,   #
#                    44, rawhide, or 'all'). Default: 44.        #
#                                                                #
# Options:                                                       #
#   -t, --test       Run scripts/test.sh immediately after build #
#   --no-cache       Build without container layer cache         #
#   --tag <NAME>     Specify a custom image tag                  #
#   -h, --help       Show this help message                      #
# -------------------------------------------------------------- #

set -o errexit
set -o nounset
set -o pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd -- "${SCRIPT_DIR}/.." && pwd)

# Determine whether to use podman or docker
if [[ -z "${CONTAINER_RUNTIME:-}" ]]; then
  if command -v podman >/dev/null 2>&1; then
    CONTAINER_RUNTIME="podman"
  elif command -v docker >/dev/null 2>&1; then
    CONTAINER_RUNTIME="docker"
  else
    printf 'Error: Neither podman nor docker was found in PATH.\n' >&2
    exit 1
  fi
fi

usage() {
  printf 'Usage: %s [VERSION] [OPTIONS]\n\n' "$0"
  printf 'Arguments:\n'
  printf '  VERSION         Fedora version (41, 42, 43, 44, rawhide, or all). Default: 44\n\n'
  printf 'Options:\n'
  printf '  -t, --test      Run scripts/test.sh right after building\n'
  printf '  --no-cache      Disable container build cache\n'
  printf '  --tag <NAME>    Custom tag to assign to the built image\n'
  printf '  -h, --help      Display this help message\n'
}

VERSION="44"
RUN_TEST=false
NO_CACHE=false
CUSTOM_TAG=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -t|--test)
      RUN_TEST=true
      shift
      ;;
    --no-cache)
      NO_CACHE=true
      shift
      ;;
    --tag)
      if [[ -z "${2:-}" ]]; then
        printf 'Error: --tag requires a value.\n' >&2
        exit 1
      fi
      CUSTOM_TAG="$2"
      shift 2
      ;;
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
      VERSION="$1"
      shift
      ;;
  esac
done

build_version() {
  local ver="$1"
  local tag="${CUSTOM_TAG:-local/gnome-shell-pod:${ver}}"
  local build_opts=()

  if [[ "${NO_CACHE}" == "true" ]]; then
    build_opts+=(--no-cache)
  fi

  printf '==============================================================\n'
  printf 'Building Fedora %s image: %s (using %s)\n' "${ver}" "${tag}" "${CONTAINER_RUNTIME}"
  printf '==============================================================\n'

  ${CONTAINER_RUNTIME} build \
    "${build_opts[@]}" \
    --build-arg fedora_version="${ver}" \
    -t "${tag}" \
    "${REPO_ROOT}"

  printf 'Successfully built image: %s\n' "${tag}"

  if [[ "${RUN_TEST}" == "true" ]]; then
    printf '\nRunning verification test suite for: %s\n' "${tag}"
    "${SCRIPT_DIR}/test.sh" "${tag}"
  fi
}

if [[ "${VERSION}" == "all" ]]; then
  for v in "41" "42" "43" "44" "rawhide"; do
    build_version "$v"
  done
else
  build_version "${VERSION}"
fi
