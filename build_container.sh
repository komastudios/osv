#!/bin/bash

# example usage:
#
#   ./build_container.sh image=httpserver-html5-gui-and-cli.fg host


BUILDER_TAG=${BUILDER_TAG:-komastudios/osv}

show_usage() {
  echo "Usage: $0 [image=<image_name>] [fs=<zfs|rofs|rofs_with_zfs|ramfs|virtiofs>]"
}

BUILD_ARGS=()

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
      echo "Unknown argument: $arg"
      show_usage
      exit 1
      ;;
  esac
done

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

buildah bud \
  --layers \
  -t ${BUILDER_TAG} \
  -f Containerfile \
  "${PODMAN_ARGS[@]}" \
  .

id=$(podman create ${BUILDER_TAG})
podman cp $id:/osv/build - | bsdtar -xvf - --include='*.img' --include='*.cmdline'
podman rm $id 1>/dev/null

echo "To run the container, execute:"
echo "  podman run -it --rm --device /dev/kvm --group-add=keep-groups ${BUILDER_TAG}"
echo "  "
echo "Or using the helper script:"
echo "  ./run_container.sh"
