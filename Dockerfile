FROM ubuntu:24.04 as builder
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && apt-get install --no-install-recommends -yq automake autoconf ca-certificates g++ git wget make pkg-config libtool xa65 libgcrypt20-dev gettext && \
    apt-get clean && rm -rf /var/lib/apt/lists/*
WORKDIR /src
RUN git clone https://github.com/libsidplayfp/libsidplayfp -b v2.11.0 --recurse-submodules
RUN git clone https://github.com/libsidplayfp/sidplayfp -b v2.11.0
WORKDIR /src/libsidplayfp
RUN autoreconf -ivf && ./configure --enable-debug && make -j$(nproc) && make install
WORKDIR /src/sidplayfp
RUN autoreconf -ivf && CFLAGS="-I/src/libsidplayfp" ./configure --enable-debug && make -j$(nproc) && make install
FROM ubuntu:24.04
RUN apt-get update && apt-get install --no-install-recommends -yq libgcrypt20 libgomp1
COPY --from=builder /usr/local /usr/local
RUN ldconfig
RUN /usr/local/bin/sidplayfp --help
ENTRYPOINT ["/usr/local/bin/sidplayfp"]
