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
