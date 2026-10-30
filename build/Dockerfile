FROM debian:trixie
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    build-essential bison ca-certificates cmake cpio file flex gawk gettext git \
    libncurses-dev libssl-dev python3 python3-setuptools rsync unzip wget xz-utils \
    zlib1g-dev zstd time && rm -rf /var/lib/apt/lists/*
RUN useradd -m -u 1000 builder
USER builder
WORKDIR /work/openwrt
