#!/bin/sh

# This script is called from the host to build a new boot ISO image.
#
# This uses Docker to start in a well-known environment. The host must have
# Docker installed and allow running privileged Docker containers. The files in
# 'inputs/' must already exist.

set -eux

# cd to this directory
cd -P -- "$(dirname -- "$0")"
cwd=$(pwd)

. ./internal/vars.sh

# Check input hashes
if ! find ./inputs -type f | \
    LC_ALL=C sort | \
    xargs sha256sum | \
    diff -u sha256sum.inputs.txt -; then
    if [ -n "${IGNORE_CHANGED_INPUTS:-}" ]; then
        echo 'WARNING: Ignoring unexpected inputs because '\$'IGNORE_CHANGED_INPUTS is set'
    else
        echo 'ERROR: Inputs are unexpected. Set '\$'IGNORE_CHANGED_INPUTS to continue'
        exit 1
    fi
fi

internal/make-cache-dir.sh target
mkdir -p target/live-build

# The resulting boot DVD image isn't supposed to be very sensitive to the
# starting build environment, since it runs mostly inside a chroot. Still, we
# use a Docker image built from a similar Debian snapshot as the boot DVD
# image. It's probably best to use a Docker image built from a snapshot that's
# about the same time or very slightly older than the 'inputs/apt' cache.
#
# The --privileged flag is needed to allow live-build to do its chrooting.
docker run \
    --init \
    --interactive \
    --net none \
    --privileged \
    --rm \
    --volume "$cwd:/ceremony:ro" \
    --volume "$cwd/target/live-build:/ceremony/target/live-build" \
    debian/snapshot:$DEBIAN_CODENAME-20230919 \
    /ceremony/internal/build-inner.sh

sha256sum ./target/live-build/ceremony-boot-amd64.iso | \
    diff -u sha256sum.output.txt -
