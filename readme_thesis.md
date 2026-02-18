# Instructions for building

The repo contains a dockerfile in order to be able to build specifically for Amazon Linux 2023, which is the version
required for depoyment on AWS. For local use, you can build the code according to the official [build instructions](https://github.com/bitcoin/bitcoin/blob/master/doc/build-unix.md).

**To build for Amazon Linux 2023:**
1. Build the container and the binaries:
```
DOCKER_BUILDKIT=1 docker build -t bitcoin-hawk-aws --output type=local,dest=./aws-build .
```