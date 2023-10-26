#!/bin/sh

# This script is called from the host to build a Windows-like filesystem image.
# The boot DVD can use this as if it's the 'C:' drive, which helps with
# testing.
#
# This requires p7zip-full and ntfs-3g to be installed but does not require
# root.
#
# It needs 'target/live-build/ceremony-boot-amd64.iso' and
# '../vendor-dvd/inputs/'.
#
# It produces 'target/win/pseudo-win.img', which is a file containing an NTFS
# filesystem.

set -eux

# cd to this directory
cd -P -- "$(dirname -- "$0")"

[ -f target/live-build/ceremony-boot-amd64.iso ]

(
    cd ../vendor-dvd
    sha256sum --check sha256sum.inputs.txt
)

umount target/win/mnt || true
rm -rf target/win
mkdir -p target/win
cd target/win

# Quiet down ntfs-3g warnings about locale.
export LC_ALL=C

truncate --size=4G pseudo-win.img
mkntfs --fast --force --quiet pseudo-win.img

mkdir mnt
mount.ntfs-3g -o big_writes pseudo-win.img mnt

mkdir -p mnt/Users/defaultuser0

7z x -so \
    ../live-build/ceremony-boot-amd64.iso \
    live/filesystem.squashfs \
    > mnt/Users/defaultuser0/filesystem.squashfs

cp -a ../../../vendor-dvd/inputs/Codesafe_Lin64-13.4.3.iso.zip \
    mnt/Users/defaultuser0/CODESAFE.ZIP
cp -a ../../../vendor-dvd/inputs/SecWorld_Lin64-13.4.4.iso.zip \
    mnt/Users/defaultuser0/SECWORLD.ZIP
cp -a ../../../vendor-dvd/inputs/nShield_HSM_Firmware-13.4.4.iso.zip \
    mnt/Users/defaultuser0/FIRMWARE.ZIP

umount mnt

echo "Created $(pwd)/pseudo-win.img"
