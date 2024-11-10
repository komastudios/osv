#!/bin/bash

RUN_ARGS=(--api)

if [ "${ARCH}" == "aarch64" ]; then
  RUN_ARGS+=(--arch=aarch64)
elif [ "${ARCH}" == "x64" ]; then
  RUN_ARGS+=(--arch=x86_64)
elif [ -n "${ARCH}" ]; then
  echo "Unknown architecture: ${ARCH}"
  exit 1
fi

./scripts/run.py "${RUN_ARGS[@]}" "$@"

# ## Custom QEMU command line (aarch64)
#
# qemu-system-aarch64 \
#   -m 1G \
#   -nographic \
#   -kernel build/release.aarch64/loader.img \
#   -append "--rootfs=rofs /hello" \
#   -machine gic-version=max \
#   -cpu cortex-a57 \
#   -machine virt \
#   -device virtio-blk-pci,id=blk0,drive=hd0 \
#   -drive file=build/release.aarch64/disk.img,if=none,id=hd0,cache=none \
#   -netdev user,id=un0,net=192.168.122.0/24,host=192.168.122.1 \
#   -device virtio-net-pci,netdev=un0 \
#   -device virtio-rng-pci
