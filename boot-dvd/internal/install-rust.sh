#!/bin/sh

# This script is called from the chroot environment (within the Docker
# container) to install Rust into the root filesystem of the vendor DVD. That
# root filesystem is later packaged up into the squashfs image.

set -eux

cd /root

# shellcheck source=internal/vars.sh
. ./vars.sh

tar -xf rust-$RUST_VERSION-x86_64-unknown-linux-gnu.tar.xz

# bindgen uses rustfmt.
rust-$RUST_VERSION-x86_64-unknown-linux-gnu/install.sh \
    --components=cargo,rustc,rustfmt-preview,rust-std-x86_64-unknown-linux-gnu

cargo version

# The PowerPC build needs rust-src to build std, which comes separately.
tar -xf rust-src-$RUST_VERSION.tar.xz
rust-src-$RUST_VERSION/install.sh

# Clean up unneeded files so they don't end up on the DVD. This is the only
# script that needs 'vars.sh'.
rm -r \
    rust-$RUST_VERSION-x86_64-unknown-linux-gnu.tar.xz \
    rust-$RUST_VERSION-x86_64-unknown-linux-gnu \
    rust-src-$RUST_VERSION.tar.xz \
    rust-src-$RUST_VERSION \
    vars.sh
