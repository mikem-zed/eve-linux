# Alpine still doesn't support riscv64 in a mainline, only on 'edge' branch
# As soon as it will be available in mainline, we can use it for 0 price
# for now one can just set ALPINE_VERSION to 'edge' for 
# experements with riscv64. Clang is a cross compiler by default and no extra
# steps are required to build for riscv64

ARG ALPINE_VERSION=3.18
FROM --platform=${BUILDPLATFORM} alpine:${ALPINE_VERSION} as builder-base
RUN apk add --no-cache \
    build-base \
    clang \
    git \
    openssl-dev \
    linux-headers \
    musl-dev \
    libgcc \
    flex \
    bison \
    lld \
    llvm \
    elfutils-dev \
    bash \
    findutils \
    diffutils \
    perl \
    ccache

ARG TARGETARCH

FROM builder-base as builder-amd64
ARG ARCH=x86_64

FROM builder-base as builder-arm64
ARG ARCH=arm64

FROM builder-base as builder-riscv64
ARG ARCH=riscv

FROM builder-${TARGETARCH} as builder
ENV KBUILD_BUILD_USER="eve"
ENV KBUILD_BUILD_HOST="eve"
ENV KCONFIG_NOTIMESTAMP="true"
# need to bind mount as readwrite so mrproper works on /src
RUN  --mount=type=bind,target=/src,readwrite \
     --mount=type=cache,target=/root/.cache/ccache \
     ccache -z && \
     # clean source tree, it should be done exactly this way (no make -C)
     cd /src && make ARCH=${ARCH} LLVM=1 -j$(nproc) mrproper && \
     # --mount=type=bind cannot mount to target=/ so we have to do out-of-tree build for kernel
     make -C /src O=/out CC="ccache clang" ARCH=${ARCH} LLVM=1 -j$(nproc) defconfig && \
     make -C /src O=/out CC="ccache clang" ARCH=${ARCH} LLVM=1 -j$(nproc) && \
     make -C /src O=/out CC="ccache clang" ARCH=${ARCH} LLVM=1 -j$(nproc) modules && \
     ccache -s



