#!/bin/bash

if [ "$(uname -m)" != "x86_64" ]; then
  echo "This script must be run on an x86_64 host"
  exit 1
fi

SRC_ROOT=$(pwd)
BUILD_ARGS=("$@")

if [ ${#BUILD_ARGS[@]} -eq 0 ]; then
  BUILD_ARGS=(image=native-example fs=rofs)
fi

if [[ "${BUILD_ARGS[@]}" == *"arch="* ]]; then
  echo "Please use the ARCH environment variable to specify the architecture"
  exit 1
fi

ARCHS=()
if [ -z "${ARCH}" ]; then
  ARCHS+=(x64 aarch64)
else
  ARCHS+=(${ARCH})
fi

for b_arch in "${ARCHS[@]}"; do
  echo "Building image (${b_arch})"

  if [ "${b_arch}" == "aarch64" ]; then
    #b_target=empty
    qemu_arch=aarch64
    CROSS_PREFIX=aarch64-linux-gnu-
  else
    qemu_arch=x86_64
  fi

  export ARCH=${b_arch}
  export CROSS_PREFIX=${CROSS_PREFIX}
  export TAR_OPTIONS=--no-same-owner # podman rootless bugfix

  ./scripts/build -j$(nproc) arch=${b_arch} "${BUILD_ARGS[@]}" || exit 1
done

for b_arch in "${ARCHS[@]}"; do
  if [ "${b_arch}" == "aarch64" ]; then
    img_name=disk.img
  else
    img_name=usr.img
  fi

  SRC_DIR="${SRC_ROOT}/build/release.${b_arch}"

  echo ""
  echo "Image built (${b_arch})"
  echo "  Image path: ${SRC_DIR}/${img_name}"
  echo "  Loader path: ${SRC_DIR}/loader.img"
done

# if [[ " ${ARCHS[@]} " =~ " x64 " ]]; then
#   ./scripts/run.py --arch=x86_64 --dry-run
# fi
