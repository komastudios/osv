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

  CONTAINER_ID=$(podman create \
    -it \
    --env "b_image=${TARGET}" \
    --env "b_arch=${b_arch}" \
    --device /dev/kvm --group-add=keep-groups \
    ${BUILDER_TAG} \
    /bin/bash -c './scripts/build -j$(nproc) arch=${b_arch} image=${b_image} && ./scripts/convert raw')

  if [ $? -ne 0 ] || [ -z "${CONTAINER_ID}" ]; then
    echo "Failed to create container"
    exit 1
  fi

  podman start -ia ${CONTAINER_ID}
  if [ $? -ne 0 ]; then
    podman rm ${CONTAINER_ID}
    exit 1
  fi

  DST_NAME="osv-${TARGET_REF}.${b_arch}.raw"

  SRC_PATH="${SRC_ROOT}/build/release.${b_arch}/osv.raw"
  DST_PATH="${DST_ROOT}/${DST_NAME}"

  echo "Copying image: ${CONTAINER_ID}:${SRC_PATH} -> ${DST_PATH}"
  mkdir -p ${DST_ROOT}
  podman cp ${CONTAINER_ID}:${SRC_PATH} ${DST_PATH}
  if [ $? -ne 0 ]; then
    echo "Failed to copy image from container"
    exit 1
  fi

  # Clean up
  podman rm -f ${CONTAINER_ID} || exit 1
done
