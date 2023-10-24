#!/bin/sh

# This script is called from the host to download Rust, as an input to the
# image builder.

set -eux

# cd to this directory
cd -P -- "$(dirname -- "$0")"

. ./internal/vars.sh

internal/make-cache-dir.sh inputs target
mkdir -p target/rust
cd target/rust

if [ ! -e rust-$RUST_VERSION-x86_64-unknown-linux-gnu.tar.xz ]; then
    curl -LO "https://static.rust-lang.org/dist/rust-$RUST_VERSION-x86_64-unknown-linux-gnu.tar.xz"
fi
if [ ! -e rust-$RUST_VERSION-x86_64-unknown-linux-gnu.tar.xz.asc ]; then
    curl -LO "https://static.rust-lang.org/dist/rust-$RUST_VERSION-x86_64-unknown-linux-gnu.tar.xz.asc"
fi
if [ ! -e rust-src-$RUST_VERSION.tar.xz ]; then
    curl -LO "https://static.rust-lang.org/dist/rust-src-$RUST_VERSION.tar.xz"
fi
if [ ! -e rust-src-$RUST_VERSION.tar.xz.asc ]; then
    curl -LO "https://static.rust-lang.org/dist/rust-src-$RUST_VERSION.tar.xz.asc"
fi
if [ ! -e rust-key.gpg.ascii ]; then
    curl -LO 'https://static.rust-lang.org/rust-key.gpg.ascii'
fi

rm -f rust.keyring
gpg \
    --no-default-keyring \
    --keyring rust.keyring \
    --import rust-key.gpg.ascii

gpg \
    --no-default-keyring \
    --keyring rust.keyring \
    --trust-model always \
    --verify \
    rust-$RUST_VERSION-x86_64-unknown-linux-gnu.tar.xz.asc \
    rust-$RUST_VERSION-x86_64-unknown-linux-gnu.tar.xz

gpg \
    --no-default-keyring \
    --keyring rust.keyring \
    --trust-model always \
    --verify \
    rust-src-$RUST_VERSION.tar.xz.asc \
    rust-src-$RUST_VERSION.tar.xz

cp -a \
    rust-$RUST_VERSION-x86_64-unknown-linux-gnu.tar.xz \
    rust-src-$RUST_VERSION.tar.xz \
    ../../inputs
