#!/bin/sh

# This script is called from the host to run a Docker container to create the
# vendor DVD ISO image. It requires the vendor's files in the 'inputs'
# directory.

set -eux

# cd to this directory
cd -P -- "$(dirname -- "$0")"
cwd=$(pwd)

. ../boot_dvd/internal/vars.sh

if [ -z "${USE_MOCK_INPUTS:-}" ]; then
    mock=
else
    mock=tests/
fi

find ./${mock}inputs -type f -not -name CACHEDIR.TAG | \
    LC_ALL=C sort | \
    xargs sha256sum | \
    diff -u ${mock}sha256sum.inputs.txt -

../boot_dvd/internal/make-cache-dir.sh target
rm -f target/vendor.iso

docker run \
    --init \
    --interactive \
    --rm \
    --volume "$cwd:/ceremony:ro" \
    --volume "/does/not/exist:/ceremony/inputs:ro" \
    --volume "$cwd/${mock}inputs:/ceremony/inputs:ro" \
    --volume "$cwd/target:/ceremony/target" \
    debian:$DEBIAN_CODENAME \
    /ceremony/make-iso-inner.sh

sha256sum ./target/vendor.iso | \
    diff -u ${mock}sha256sum.output.txt -
