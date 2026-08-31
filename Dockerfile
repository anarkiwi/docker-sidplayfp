# syntax=docker/dockerfile:1

# Pinned upstream releases, updated by .github/workflows/upstream-bump.yml.
# The image release version is derived from SIDPLAYFP_VERSION. The three
# projects version independently, so they are pinned separately.
#
# libresidfp is not optional: since libsidplayfp 3.x the SID engine lives in
# its own project, and libsidplayfp's configure only warns when it is missing,
# producing a library that fails at play time with "Requested SID emulation not
# built in". tests/smoke.sh plays a tune to catch that.
ARG SIDPLAYFP_VERSION=v3.2.0
ARG LIBSIDPLAYFP_VERSION=v3.1.1
ARG LIBRESIDFP_VERSION=v1.2.2

FROM ubuntu:26.04 AS builder
ARG SIDPLAYFP_VERSION
ARG LIBSIDPLAYFP_VERSION
ARG LIBRESIDFP_VERSION
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install --no-install-recommends -yq automake autoconf ca-certificates g++ git wget make pkg-config libtool xa65 libgcrypt20-dev gettext && \
    apt-get clean && rm -rf /var/lib/apt/lists/*
ENV PKG_CONFIG_PATH=/usr/local/lib/pkgconfig
WORKDIR /src
RUN git clone https://github.com/libsidplayfp/libresidfp -b ${LIBRESIDFP_VERSION}
RUN git clone https://github.com/libsidplayfp/libsidplayfp -b ${LIBSIDPLAYFP_VERSION} --recurse-submodules
RUN git clone https://github.com/libsidplayfp/sidplayfp -b ${SIDPLAYFP_VERSION}
WORKDIR /src/libresidfp
RUN autoreconf -ivf && ./configure && make -j"$(nproc)" && make install
WORKDIR /src/libsidplayfp
RUN autoreconf -ivf && ./configure --enable-debug && make -j"$(nproc)" && make install \
    && ldd /usr/local/lib/libsidplayfp.so | grep -q residfp
WORKDIR /src/sidplayfp
RUN autoreconf -ivf && CFLAGS="-I/src/libsidplayfp" ./configure --enable-debug && make -j"$(nproc)" && make install

FROM ubuntu:26.04
ARG SIDPLAYFP_VERSION
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install --no-install-recommends -yq libgcrypt20 libgomp1 && \
    apt-get clean && rm -rf /var/lib/apt/lists/*
COPY --from=builder /usr/local /usr/local
RUN ldconfig
RUN /usr/local/bin/sidplayfp --help
ENV SIDPLAYFP_VERSION=${SIDPLAYFP_VERSION}
ENTRYPOINT ["/usr/local/bin/sidplayfp"]

LABEL org.opencontainers.image.title="sidplayfp" \
      org.opencontainers.image.description="sidplayfp C64 SID player" \
      org.opencontainers.image.version="${SIDPLAYFP_VERSION}" \
      org.opencontainers.image.source="https://github.com/anarkiwi/docker-sidplayfp" \
      org.opencontainers.image.url="https://github.com/libsidplayfp/sidplayfp" \
      org.opencontainers.image.licenses="GPL-2.0-or-later"
