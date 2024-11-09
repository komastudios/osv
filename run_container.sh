#!/bin/bash

IMAGE_TAG=komastudios/osv
KVM_ARGS=(--device /dev/kvm --group-add=keep-groups)
#required arguments for KVM support: (--device /dev/kvm --group-add=keep-groups)

podman run \
  -it --rm \
  --network=host \
  --name osv_runner \
  "${KVM_ARGS[@]}" \
  $IMAGE_TAG \
  "$@"
