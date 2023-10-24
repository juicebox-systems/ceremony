#!/bin/sh

# This script is called from the host/CI to run a Docker container to check the
# mock vendor DVD ISO image contents. It requires the mock vendor ISO to be
# built first.

set -eux

# cd to the vendor_dvd directory
cd -P -- "$(dirname -- "$0")"/..
cwd=$(pwd)

. ../boot_dvd/internal/vars.sh

hexdump -C target/vendor.iso | diff -u tests/iso.txt -

docker run \
    --init \
    --interactive \
    --privileged \
    --rm \
    --volume "$cwd:/ceremony:ro" \
    --volume "$cwd/target:/ceremony/target" \
    --volume "$cwd/target/vendor.iso:/ceremony/target/vendor.iso:ro" \
    debian:$DEBIAN_CODENAME \
    /ceremony/tests/test-mock-iso-inner.sh
