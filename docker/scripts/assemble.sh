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

ARCHS=(x64)
if [ -z "${ARCH}" ] || [ "${ARCH}" == "aarch64" ]; then
  ARCHS+=(aarch64)
elif [ "${ARCH}" != "x64" ]; then
  echo "Unsupported ARCH argument: ${ARCH}"
  exit 1
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
  ./scripts/run.py --arch=${qemu_arch} --dry-run > ${SRC_ROOT}/build/release.${b_arch}/qemu.cmdline
done

for b_arch in "${ARCHS[@]}"; do
  SRC_DIR="${SRC_ROOT}/build/release.${b_arch}"

  if [ ! -d "${SRC_DIR}" ]; then
    continue
  fi

  echo ""
  echo "Image built (${b_arch})"
  echo "  Image path: ${SRC_DIR}/usr.img"
  echo "  Loader path: ${SRC_DIR}/loader.img"

  qemu_cmd=${SRC_DIR}/qemu.cmdline
  if [ -f "${qemu_cmd}" ]; then
    echo "  QEMU command line: $(cat ${qemu_cmd})"
  fi
done
