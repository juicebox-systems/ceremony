#!/bin/sh

# This script runs on the host or in CI to run tests requiring the vendor's
# Codesafe archive. It verifies that the build outputs hash the same as
# '../internal/hashes.txt' and runs the vendor-specific unit tests.
#
# This script requires the Codesafe input archive in the '../vendor-dvd/inputs'
# directory. It runs a privileged Docker container.

set -eux

# cd to boot-dvd directory
cd -P -- "$(dirname -- "$0")"/..

# The --privileged flag is needed to mount the ISO.
docker run \
    --interactive \
    --net none \
    --privileged \
    --rm \
    --volume "$PWD":/ceremony/boot-dvd:ro \
    --volume "$PWD/../vendor-dvd/inputs/Codesafe_Lin64-13.4.3.iso.zip":/run/win/Users/defaultuser0/CODESAFE.ZIP:ro \
    ceremony-root \
    /ceremony/boot-dvd/tests/test-codesafe-inner.sh
