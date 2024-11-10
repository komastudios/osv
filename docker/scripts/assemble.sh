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

export ARCH=${ARCH:-x64}
if [ "${ARCH}" != "x64" ] && [ "${ARCH}" != "aarch64" ]; then
  echo "Unsupported ARCH: ${ARCH}"
  exit 1
fi

if [ "${ARCH}" == "aarch64" ]; then
  image=disk.img
  qemu_arch=aarch64
  export CROSS_PREFIX=aarch64-linux-gnu-
else
  image=usr.img
  qemu_arch=x86_64
  export CROSS_PREFIX=""
fi

echo "ARCH=${ARCHS[@]}"
echo "BUILD_ARGS=${BUILD_ARGS[@]}"
echo "CROSS_PREFIX=${CROSS_PREFIX}"

export TAR_OPTIONS=--no-same-owner # podman rootless bugfix

SRC_DIR=${SRC_ROOT}/build/release.${ARCH}

./scripts/build -j$(nproc) arch=${ARCH} "${BUILD_ARGS[@]}" || exit 1
./scripts/run.py --arch=${qemu_arch} --dry-run | tee ${SRC_DIR}/qemu.cmdline

echo ""
echo "Image built (${ARCH})"
echo "  Image path: ${SRC_DIR}/${image}"
echo "  Loader path: ${SRC_DIR}/loader.img"
