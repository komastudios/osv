ARG BUILD_ARGS="image=default fs=rofs"

## --- base image
FROM docker.io/ubuntu:22.04 AS base-image

ENV DEBIAN_FRONTEND noninteractive
ENV TERM=linux

COPY ./docker/etc/keyboard /etc/default/keyboard
COPY ./docker/etc/console-setup /etc/default/console-setup

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
        binutils-aarch64-linux-gnu \
        nodejs \
        npm

ARG VENDOR_MIRROR=https://
ENV VENDOR_MIRROR=${VENDOR_MIRROR}

COPY scripts/setup.py scripts/linux_distro.py /osv/scripts/

# - update all required packages in case they have changed
WORKDIR /osv
RUN scripts/setup.py

# - install Capstan
ADD ${VENDOR_MIRROR}github.com/cloudius-systems/capstan/releases/latest/download/capstan /usr/local/bin/
RUN chmod u+x /usr/local/bin/capstan

COPY scripts/download_aarch64_packages.py \
     scripts/download_ubuntu_aarch64_deb_package.sh \
     /osv/scripts/

RUN scripts/download_aarch64_packages.py \
 && ln -s libyaml-cpp.so.0.7 /usr/lib/aarch64-linux-gnu/libyaml-cpp.so

## --- build environment (including sources)
FROM base-image AS builder

COPY LICENSE Makefile *.S *.skel *.json *.cc /osv/
COPY apps/ /osv/apps/
COPY arch/ /osv/arch/
COPY bsd/ /osv/bsd/
COPY compiler/ /osv/compiler/
COPY conf/ /osv/conf/
COPY core/ /osv/core/
COPY drivers/ /osv/drivers/
COPY exported_symbols/ /osv/exported_symbols/
COPY external/ /osv/external/
COPY fastlz/ /osv/fastlz/
COPY fs/ /osv/fs/
COPY images/ /osv/images/
COPY include/ /osv/include/
COPY libc/ /osv/libc/
COPY licenses/ /osv/licenses/
COPY modules/ /osv/modules/
COPY musl/ /osv/musl/
COPY musl_0.9.12/ /osv/musl_0.9.12/
COPY musl_1.1.24/ /osv/musl_1.1.24/
COPY scripts/ /osv/scripts/
COPY static/ /osv/static/
COPY tests/ /osv/tests/
COPY tools/ /osv/tools/
WORKDIR /osv

## --- final build image
FROM builder AS build

WORKDIR /osv

ARG ARCH
ARG BUILD_ARGS

COPY docker/scripts/assemble.sh \
     /osv/docker/scripts/
RUN docker/scripts/assemble.sh ${BUILD_ARGS}

COPY docker/scripts/run.sh \
     /osv/docker/scripts/

EXPOSE 8000
ENTRYPOINT docker/scripts/run.sh
