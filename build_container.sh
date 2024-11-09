#!/bin/bash

# example usage:
#
#   ./build_container.sh image=httpserver-html5-gui-and-cli.fg host

builder_tag=${BUILDER_TAG:-komastudios/osv}

show_usage() {
  echo "Usage: $0 [image=<image_name>] [fs=<zfs|rofs|rofs_with_zfs|ramfs|virtiofs>]"
}

build_args=()

for arg in "$@"; do
  case $arg in
    -h|--help)
      show_usage
      exit 0
      ;;
    *=*)
      key=${arg%%=*}
      value=${arg#*=}
      build_args+=("${arg}")
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

podman_args=()
if [[ ${#build_args[@]} -ne 0 ]]; then
  podman_args+=(--build-arg "BUILD_ARGS=${build_args[*]}")
fi

podman_args+=(--build-arg "VENDOR_MIRROR=https://ftp.mirror.koma.systems/vendor/")

buildah bud \
  "${podman_args[@]}" \
  -t ${builder_tag} \
  -f Containerfile \
  --layers \
  .

id=$(podman create ${builder_tag})
podman cp $id:/osv/build - | bsdtar -xvf - --include='*.img' --include='*.cmdline'
podman rm $id 1>/dev/null

echo "To run the container, execute:"
echo "  podman run -it --rm --device /dev/kvm --group-add=keep-groups ${builder_tag}"
echo "  "
echo "Or using the helper script:"
echo "  ./run_container.sh"
