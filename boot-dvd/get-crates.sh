#!/bin/sh

# This script is called from the host to run a Docker container to download
# dependencies' source code into a local Cargo registry, as an input to the
# image builder.
#
# It requires official Rust packages and Juicebox's code in the 'inputs'
# directory.
set -eux

# cd to this directory
cd -P -- "$(dirname -- "$0")"
cwd=$(pwd)

. ./internal/vars.sh

internal/make-cache-dir.sh target
mkdir -p inputs/crates target/crates

docker run \
    --env HOST_USER="$(id -u):$(id -g)" \
    --init \
    --interactive \
    --rm \
    --volume "$cwd:/ceremony:ro" \
    --volume "$cwd/inputs/crates:/ceremony/inputs/crates" \
    --volume "$cwd/target/crates:/ceremony/target/crates" \
    debian:$DEBIAN_CODENAME \
    /ceremony/internal/get-crates-inner.sh
