#!/bin/sh

# This script is called from a Docker container to create the vendor DVD ISO
# image. This is normally run through Docker with 'make-iso.sh'. It requires
# the vendor's files in the 'inputs' directory.

set -eux

# cd to this directory
cd -P -- "$(dirname -- "$0")"

# Quiet down complains from debconf about `dialog` being unavailable.
export DEBIAN_FRONTEND=noninteractive

apt update
apt install --no-install-recommends --yes xorriso

# Set fake timestamps for reproducibility.
# See https://reproducible-builds.org/docs/source-date-epoch/
SOURCE_DATE_EPOCH=$(date -u -d 2023-01-01 +'%s')
export SOURCE_DATE_EPOCH

rm -f target/vendor.iso

xorriso \
    -abort_on WARNING \
    -indev stdio:/dev/null \
    -outdev target/vendor.iso \
    -charset ISO-8859-1 \
    -compliance 'clear:iso_9660_level=1:always_gmt:no_emul_toc' \
    -disk_pattern off \
    -rockridge off \
    -volid 'VENDOR' \
    -map inputs/Codesafe_Lin64-13.4.3.iso.zip CODESAFE.ZIP \
    -map inputs/SecWorld_Lin64-13.4.4.iso.zip SECWORLD.ZIP \
    -map inputs/nShield_HSM_Firmware-13.4.4.iso.zip FIRMWARE.ZIP

chown "$HOST_USER" target/vendor.iso
