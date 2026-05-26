FROM amazonlinux:2023 AS builder

RUN dnf install -y \
  gcc gcc-c++ make cmake git python3 \
  patch libtool automake autoconf pkg-config \
  xz bzip2 which

WORKDIR /build

COPY depends/ depends/
RUN --mount=type=cache,target=/build/depends/built \
  cd depends && make -j8 NO_QT=1

COPY . .
RUN --mount=type=cache,target=/build/build_aws \
  cmake -B build_aws \
  -DENABLE_TESTS=OFF \
  -DBUILD_BITCOIN_WALLET=ON \
  -DENABLE_BENCH=OFF \
  -DWITH_ZMQ=ON \
  -DCMAKE_TOOLCHAIN_FILE=depends/x86_64-pc-linux-gnu/toolchain.cmake && \
  cmake --build build_aws --parallel 8 --target bitcoind bitcoin-cli && \
  mkdir -p /build/output && \
  cp build_aws/bin/bitcoind build_aws/bin/bitcoin-cli /build/output/

FROM scratch
COPY --from=builder /build/output/ /