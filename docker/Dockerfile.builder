#
# Copyright (C) 2020 Waldemar Kozaczuk
#
# This work is open source software, licensed under the terms of the
# BSD license as described in the LICENSE file in the top-level directory.
#
# This Docker file defines an image based on Ubuntu distribution and provides
# all packages necessary to build and run kernel and applications.
#
ARG DIST_VERSION=22.04
FROM docker.io/ubuntu:${DIST_VERSION}

ENV DEBIAN_FRONTEND noninteractive
ENV TERM=linux

COPY ./etc/keyboard /etc/default/keyboard
COPY ./etc/console-setup /etc/default/console-setup

RUN apt-get update -y && apt-get install -y git python3 python3-distro

RUN dpkg --add-architecture arm64 \
 && echo "deb [arch=arm64] http://ports.ubuntu.com/ jammy main restricted\n" \
         "deb [arch=arm64] http://ports.ubuntu.com/ jammy-updates main restricted\n" \
         "deb [arch=arm64] http://ports.ubuntu.com/ jammy universe\n" \
         "deb [arch=arm64] http://ports.ubuntu.com/ jammy-updates universe\n" \
         "deb [arch=arm64] http://ports.ubuntu.com/ jammy multiverse\n" \
         "deb [arch=arm64] http://ports.ubuntu.com/ jammy-updates multiverse\n" \
         "deb [arch=arm64] http://ports.ubuntu.com/ jammy-backports main restricted universe multiverse" \
  | tee /etc/apt/sources.list.d/arm-cross-compile-sources.list \
 && cp /etc/apt/sources.list "/etc/apt/sources.list.`date`.backup" \
 && sed -i -E "s/(deb)\ (http:.+)/\1\ [arch=amd64]\ \2/" /etc/apt/sources.list \
 && apt-get update -y \
 && apt-get install -y \
        libc6-arm64-cross \
        libc6-dev-arm64-cross \
        libstdc++-11-dev-arm64-cross \
        libstdc++6-arm64-cross \
        openssl:arm64 \
        libssl-dev:arm64 \
        libedit-dev:arm64 \
        libncurses5-dev:arm64 \
        libyaml-cpp-dev:arm64 \
        libboost1.74-dev:arm64 \
        libboost-system1.74:arm64 \
        libboost-system1.74-dev:arm64 \
        libboost-filesystem1.74:arm64 \
        libboost-filesystem1.74-dev:arm64 \
        libboost-test1.74:arm64 \
        libboost-test1.74-dev:arm64 \
        libboost-timer1.74:arm64 \
        libboost-timer1.74-dev:arm64 \
        libboost-program-options1.74:arm64 \
        libboost-program-options1.74-dev:arm64 \
        libboost-chrono1.74:arm64 \
        libboost-chrono1.74-dev:arm64 \
        gcc-aarch64-linux-gnu \
        g++-aarch64-linux-gnu \
        binutils-aarch64-linux-gnu

#
# PREPARE ENVIRONMENT
#

# - prepare directories
RUN mkdir -p /git-repos

# - clone OSv
ARG GIT_ORG_OR_USER=komastudios
ARG GIT_BRANCH=master

WORKDIR /git-repos
RUN git clone https://github.com/${GIT_ORG_OR_USER}/osv.git

WORKDIR /git-repos/osv
RUN git checkout ${GIT_BRANCH}
RUN git submodule update --init --recursive

ARG VENDOR_MIRROR=https://
ENV VENDOR_MIRROR=${VENDOR_MIRROR}

# - update all required packages in case they have changed
RUN scripts/setup.py

# - install Capstan
ADD ${VENDOR_MIRROR}github.com/cloudius-systems/capstan/releases/latest/download/capstan /usr/local/bin/
RUN chmod u+x /usr/local/bin/capstan

RUN scripts/download_aarch64_packages.py

WORKDIR /git-repos/osv
CMD /bin/bash

ENV TAR_OPTIONS=--no-same-owner
