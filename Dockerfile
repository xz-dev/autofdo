FROM docker.io/archlinux:base-devel
    MAINTAINER xz <xiangzhedev@gmail.com>

RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm wget unzip git libpfm devtools perf time llvm
RUN useradd --no-create-home --shell=/bin/sh build && usermod -L build

RUN wget https://github.com/google/autofdo/releases/download/v0.30.1/create_llvm_prof-x86_64-v0.30.1.zip -O /tmp/create_llvm_prof-x86_64-v0.30.1.zip && \
    unzip /tmp/create_llvm_prof-x86_64-v0.30.1.zip -d /usr/bin/ && \
    chmod +x /usr/bin/create_llvm_prof && \
    rm -rf /tmp/*

RUN git clone --depth=1 https://aur.archlinux.org/linux-cachyos.git /linux-cachyos

RUN chown -R build:build /linux-cachyos
RUN bash -c 'source /linux-cachyos/PKGBUILD && pacman -Syu --noconfirm && pacman -S --noconfirm --needed --asdeps "${makedepends[@]}" "${depends[@]}"'

RUN wget https://download.blender.org/release/BlenderBenchmark2.0/launcher/benchmark-launcher-cli-3.1.0-linux.tar.gz -O /tmp/benchmark-launcher-cli-3.1.0-linux.tar.gz && \
    tar -xvf /tmp/benchmark-launcher-cli-3.1.0-linux.tar.gz -C /tmp/ && \
    mv /tmp/benchmark-launcher-cli /usr/bin/ && \
    chmod +x /usr/bin/benchmark-launcher-cli && \
    rm -rf /tmp/*

RUN pacman -S --noconfirm xorg libxkbcommon

RUN benchmark-launcher-cli blender download 4.3.0 && \
    benchmark-launcher-cli scenes download --blender-version 4.3.0 monster junkshop classroom

RUn wget https://github.com/phoronix-test-suite/phoronix-test-suite/archive/refs/heads/master.zip -O /tmp/phoronix-test-suite.zip && \
    unzip /tmp/phoronix-test-suite.zip -d /tmp/ && \
    mv /tmp/phoronix-test-suite-master /phoronix-test-suite && \
    cd /phoronix-test-suite && \
    ./install-sh && \
    cd / && \
    rm -rf /tmp/*

RUN pacman -S --noconfirm php

RUN phoronix-test-suite install cpu
#RUN phoronix-test-suite install-dependencies cpu
COPY phoronix-test-suite.xml /etc/phoronix-test-suite.xml

COPY build.sh /usr/bin/build.sh
RUN chmod +x /usr/bin/build.sh

WORKDIR /linux-cachyos

ENTRYPOINT ["/usr/bin/build.sh"]
