#!/bin/sh

# This script is called from a privileged Docker container to check the mock
# vendor DVD ISO image contents. It's normally run through 'test-mock-iso.sh'.
# It requires the mock vendor ISO to be built first.

set -eux

# cd to the vendor-dvd directory
cd -P -- "$(dirname -- "$0")"/..

mkdir -p /run/dvd
mount -o ro target/vendor.iso /run/dvd # requires privileged docker, probably

(
    cd /run/dvd
    find . | LC_ALL=C sort
    # Note: Linux maps the names to lowercase.
    sha256sum codesafe.zip firmware.zip secworld.zip
    head codesafe.zip firmware.zip secworld.zip
) | diff -u tests/contents.txt -

umount /run/dvd
