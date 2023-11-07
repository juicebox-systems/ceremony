#!/bin/sh

# This script runs on the build host or in CI to create a Docker image from the
# squashfs filesystem of a boot dvd ISO. This is useful for testing without
# using a full virtual machine.
#
# This script requires docker, p7zip-full, squashfs-tools, and sudo.

set -eux

# cd to boot-dvd directory
cd -P -- "$(dirname -- "$0")"/..

sudo rm -rf target/test-squashfs
mkdir target/test-squashfs
cd target/test-squashfs
7z x ../live-build/ceremony-boot-amd64.iso live/filesystem.squashfs
sudo unsquashfs live/filesystem.squashfs
cd squashfs-root
sudo tar -c . | docker import - ceremony-root
cd ../../..
sudo rm -rf target/test-squashfs
