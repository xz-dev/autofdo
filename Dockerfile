FROM docker.io/archlinux:base-devel
    MAINTAINER xz <xiangzhedev@gmail.com>

RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm wget unzip

RUN wget https://github.com/phoronix-test-suite/phoronix-test-suite/archive/refs/heads/master.zip -O /tmp/phoronix-test-suite.zip && \
    unzip /tmp/phoronix-test-suite.zip -d /tmp/ && \
    mv /tmp/phoronix-test-suite-master /phoronix-test-suite && \
    cd /phoronix-test-suite && \
    ./install-sh && \
    cd / && \
    rm -rf /tmp/*

RUN pacman -S --noconfirm php

#RUN phoronix-test-suite install cpu
#RUN phoronix-test-suite install-dependencies cpu
# Due network is slow, easier to retry
RUN phoronix-test-suite install pts/rodinia
RUN phoronix-test-suite install pts/namd
RUN phoronix-test-suite install pts/stockfish
RUN phoronix-test-suite install pts/x264
RUN phoronix-test-suite install pts/x265
RUN phoronix-test-suite install pts/kvazaar
RUN phoronix-test-suite install pts/compress-7zip
RUN phoronix-test-suite install pts/blender
RUN phoronix-test-suite install pts/asmfish
RUN phoronix-test-suite install pts/build-linux-kernel
RUN phoronix-test-suite install pts/build-gcc
RUN phoronix-test-suite install pts/radiance
RUN phoronix-test-suite install pts/openssl
RUN phoronix-test-suite install pts/ctx-clock
RUN phoronix-test-suite install pts/sysbench
RUN phoronix-test-suite install pts/povray
COPY phoronix-test-suite.xml /etc/phoronix-test-suite.xml
ENV FORCE_TIMES_TO_RUN=1

RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm libpfm devtools perf llvm

RUN wget https://github.com/google/autofdo/releases/download/v0.30.1/create_llvm_prof-x86_64-v0.30.1.zip -O /tmp/create_llvm_prof-x86_64-v0.30.1.zip && \
    unzip /tmp/create_llvm_prof-x86_64-v0.30.1.zip -d /usr/bin/ && \
    chmod +x /usr/bin/create_llvm_prof && \
    rm -rf /tmp/*

RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm time

COPY build.py /usr/bin/build.py
RUN chmod +x /usr/bin/build.py

WORKDIR /

ENTRYPOINT ["/usr/bin/build.py"]
