#!/bin/bash

# example usage:
#
#   ./build_container.sh image=httpserver-html5-gui-and-cli.fg host


BUILDER_TAG=${BUILDER_TAG:-komastudios/osv}

show_usage() {
  echo "Usage: $0 <host|x64|aarch64|all>"
}

BUILD_ARGS=()

TARGET=""

for arg in "$@"; do
  case $arg in
    -h|--help)
      show_usage
      exit 0
      ;;
    *=*)
      key=${arg%%=*}
      value=${arg#*=}
      BUILD_ARGS+=($arg)
      ;;
    *)
      key=""
      TARGET=$arg
      ;;
  esac
done

if [ -z "${TARGET}" ]; then
  show_usage
  exit 1
fi

if [ "$(uname -m)" != "x86_64" ]; then
  echo "This script must be run on an x86_64 host"
  exit 1
fi
HOST_ARCH=x64

PODMAN_ARGS=()

if [ ${#BUILD_ARGS[@]} -ne 0 ]; then
  PODMAN_ARGS+=(--build-arg "BUILD_ARGS=${BUILD_ARGS[@]}")
fi

PODMAN_ARGS+=(--build-arg "VENDOR_MIRROR=https://ftp.mirror.koma.systems/vendor/")

if [[ $TARGET == "host" ]]; then
  PODMAN_ARGS+=(--build-arg "ARCH=${HOST_ARCH}")
elif [[ $TARGET =~ x64|x86_64 ]]; then
  PODMAN_ARGS+=(--build-arg "ARCH=x64")
elif [[ $TARGET =~ arm64|aarch64 ]]; then
  PODMAN_ARGS+=(--build-arg "ARCH=aarch64")
elif [[ $TARGET != "all" ]]; then
  echo "Unknown target: ${TARGET}"
  exit 1
fi

buildah bud \
  --layers \
  -t ${BUILDER_TAG} \
  -f Containerfile \
  "${PODMAN_ARGS[@]}" \
  .

echo "To run the container, execute:"
echo "  podman run -it --rm --device /dev/kvm --group-add=keep-groups ${BUILDER_TAG}"
echo "  "
echo "Or using the helper script:"
echo "  ./run_container.sh"
