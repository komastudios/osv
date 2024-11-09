#!/bin/bash

if [ -z "${GIT_BRANCH}" ]; then
  GIT_REV=$(git rev-parse HEAD)
  if [ $? -eq 0 ]; then
    GIT_BRANCH=${GIT_REV}
  fi
fi

BUILDER_TAG=osv/builder
GIT_ORG_OR_USER=komastudios
ARCHS=()
if [ -z "${ARCH}" ]; then
  ARCHS+=(x64 aarch64)
else
  ARCHS+=(${ARCH})
fi

TARGET=${1:-default}
TARGET_REF=${TARGET//[^[:alnum:]]/-}

podman build \
  -t ${BUILDER_TAG} \
  -f Dockerfile.builder \
  --build-arg "VENDOR_MIRROR=https://ftp.mirror.koma.systems/vendor/" \
  --build-arg GIT_ORG_OR_USER=${GIT_ORG_OR_USER} \
  --build-arg GIT_BRANCH=${GIT_BRANCH} \
  .

if [ $? -ne 0 ]; then
  echo "Failed to build builder image"
  exit 1
fi

SRC_ROOT=/git-repos/osv
DST_ROOT=build

for b_arch in "${ARCHS[@]}"; do
  echo "Building image (${b_arch})"
  
  if [ "${b_arch}" == "aarch64" ]; then
    b_target=uush
    img_name=disk.img
  else
    b_target=default
    img_name=usr.img
  fi

  b_cmd='./scripts/build -j$(nproc) arch=${b_arch} image=${b_image}'

  CONTAINER_ID=$(podman create \
    -it \
    --env "b_image=${b_target}" \
    --env "b_arch=${b_arch}" \
    --device /dev/kvm --group-add=keep-groups \
    ${BUILDER_TAG} \
    /bin/bash -c "$b_cmd")

  if [ $? -ne 0 ] || [ -z "${CONTAINER_ID}" ]; then
    echo "Failed to create container"
    exit 1
  fi

  podman start -ia ${CONTAINER_ID}
  if [ $? -ne 0 ]; then
    podman rm ${CONTAINER_ID}
    exit 1
  fi

  SRC_DIR="${SRC_ROOT}/build/release.${b_arch}"
  SRC_PATH="${SRC_DIR}/osv.raw"
  
  DST_NAME="osv-${TARGET_REF}.${b_arch}"

  echo "Copying image: ${CONTAINER_ID}:${SRC_DIR}/${img_name} -> ${DST_ROOT}/${DST_NAME}.img"
  mkdir -p ${DST_ROOT}
  podman cp ${CONTAINER_ID}:${SRC_DIR}/${img_name} ${DST_ROOT}/${DST_NAME}.img
  podman cp ${CONTAINER_ID}:${SRC_DIR}/loader.img ${DST_ROOT}/loader.${b_arch}.img
  podman cp ${CONTAINER_ID}:${SRC_DIR}/loader.elf ${DST_ROOT}/loader.${b_arch}.elf
  podman cp ${CONTAINER_ID}:${SRC_DIR}/loader-stripped.elf ${DST_ROOT}/loader-stripped.${b_arch}.elf
  if [ $? -ne 0 ]; then
    echo "Failed to copy image from container"
    exit 1
  fi

  # Clean up
  podman rm -f ${CONTAINER_ID} || exit 1
done
