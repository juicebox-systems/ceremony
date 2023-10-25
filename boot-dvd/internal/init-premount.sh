#!/bin/sh

# This script runs within the initrd image of the boot DVD, during the early
# boot process. It applies an optimization to avoid reading too much from the
# slow DVD drive. It compares the SHA-256 hash of
# 'C:\Users\defaultuser0\filesystem.squashfs' with the DVD's 'sha256sum.txt'
# and, if valid, arranges for that copy of the squashfs filesystem to be
# mounted later in the boot process (instead of the DVD's copy).

set -eu

if [ "${1-}" = 'prereqs' ]; then
    echo ntfs_3g
    exit 0
fi

# Load definition of 'panic'.
# shellcheck disable=SC1091
. /scripts/functions

# This is harmless and needed to mount the squashfs later.
modprobe loop

mkdir /run/dvd
mount -t iso9660 -o ro /dev/sr0 /run/dvd
expected=$(sed -En 's|^(.*)  \./live/filesystem\.squashfs$|\1|p' /run/dvd/sha256sum.txt)
umount /run/dvd

if [ ${#expected} -ne 64 ]; then
    set +eu
    panic "Couldn't find hash of filesystem.squashfs in the DVD's sha256sum.txt"
    exit 1
fi
echo "Looking for C:\Users\defaultuser0\filesystem.squashfs with hash $expected"

mkdir /run/win
# The /dev/sda path is used for KVM/QEMU testing with a "pseudo-Windows"
# filesystem image; see '../make-win.sh'.
mount -t ntfs-3g -o ro /dev/nvme0n1p3 /run/win || \
    mount -t ntfs-3g -o ro /dev/sda /run/win || \
    true

# Note that if the file isn't found, the script will continue, since the failure
# isn't at the end of the pipeline. The variable will be empty.
actual=$(sha256sum /run/win/Users/defaultuser0/filesystem.squashfs | cut -f1 -d' ')

if [ "$actual" = "$expected" ]; then
    echo "Found C:\Users\defaultuser0\filesystem.squashfs with correct hash"
    mkdir -p /etc/live/boot
    cat > /etc/live/boot/wincache <<'END'
PLAIN_ROOT=true
ROOT=/run/win/Users/defaultuser0/filesystem.squashfs
END
else
    set +eu
    cat <<'END'
WARNING: C:\Users\defaultuser0\filesystem.squashfs not found or invalid hash.
Panicking soon. You can exit the (initramfs) shell to continue booting without
the cached boot DVD filesystem image.
END
    panic 'C:\Users\defaultuser0\filesystem.squashfs not found or invalid hash'
fi
