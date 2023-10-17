#!/bin/sh

set -eux

# cd to tool directory
cd -P -- "$(dirname -- "$0")/.."
cwd=$(pwd)

if cargo version; then
    cargo build
else
    echo "WARNING: cargo not installed, not building tool"
fi

rm -rf target/realm_dvd
mkdir -p target/realm_dvd

# privileged to be able to mount the ISO
docker run \
    --privileged \
    --rm \
    --volume "$cwd/target/debug/ceremony:/usr/local/bin/ceremony:ro" \
    --volume "$cwd/target/realm_dvd:/output/" \
    --volume "$cwd/tests/realm_dvd_inner.sh:/usr/local/bin/realm_dvd_inner.sh:ro" \
    debian:12 \
    realm_dvd_inner.sh

hexdump -C target/realm_dvd/realm.iso > tests/realm.iso.actual.txt
diff -u tests/realm.iso.txt tests/realm.iso.actual.txt
rm tests/realm.iso.actual.txt
