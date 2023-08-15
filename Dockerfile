FROM --platform=${BUILDPLATFORM} alpine:3.18 as builder-base
RUN apk add --no-cache \
    build-base \
    clang \
    git \
    openssl-dev

    # clang-dev \
    # cmake \
    # git \
    # libffi-dev \
    # linux-headers \
    # openssl-dev \
    # python3 \
    # python3-dev \
    # py3-pip \
    # py3-wheel \
    # py3-setuptools \
    # zlib-dev

ARG TARGETARCH

FROM builder-base as builder-amd64
ARG ARCH=x86_64

FROM builder-base as builder-arm64
ARG ARCH=arm64

FROM builder-${TARGETARCH} as builder
COPY . .
RUN make ARCH=${ARCH} LLVM=1 -j$(nproc) defconfig
RUN make ARCH=${ARCH} LLVM=1 -j$(nproc) bzImage



