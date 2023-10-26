#!/bin/sh

# This script is called from a Docker container to download dependencies'
# source code into a local Cargo registry, as an input to the image builder.
#
# This is normally run through Docker with 'get-crates.sh'.
#
# It requires official Rust packages and Juicebox's code in the 'inputs'
# directory.

set -eux

# cd to the boot-dvd directory
cd -P -- "$(dirname -- "$0")"/..

. ./internal/vars.sh

# Quiet down complains from debconf about `dialog` being unavailable.
export DEBIAN_FRONTEND=noninteractive

apt update
apt install --no-install-recommends --yes \
    ca-certificates \
    gcc \
    libc6-dev \
    libssl-dev \
    pkg-config \
    xz-utils

mkdir -p target/crates
cd target/crates
find . -mindepth 1 -delete

tar -xf ../../inputs/rust-$RUST_VERSION-x86_64-unknown-linux-gnu.tar.xz
rust-$RUST_VERSION-x86_64-unknown-linux-gnu/install.sh \
    --components=cargo,rustc,rust-std-x86_64-unknown-linux-gnu

cargo install cargo-local-registry@0.2.6

tar -xf ../../inputs/ceremony-tool.tar
tar -xf ../../inputs/juicebox-hsm-realm.tar
tar -xf ../../inputs/rust-src-$RUST_VERSION.tar.xz

RUST_SRC_DIR=rust-src-$RUST_VERSION/rust-src/lib/rustlib/src/rust
# The libraries don't use a Cargo workspace but share a single lock file. This
# hack copies the lock file so 'cargo local-registry' can find it. The
# dependencies for the sysroot library seem to suffice.
cp -a $RUST_SRC_DIR/Cargo.lock $RUST_SRC_DIR/library/sysroot/

mkdir cargo-registry
cargo local-registry \
    --no-delete \
    --sync ceremony/tool/Cargo.lock \
    cargo-registry
cargo local-registry \
    --no-delete \
    --sync juicebox-hsm-realm/Cargo.lock \
    cargo-registry
cargo local-registry \
    --no-delete \
    --sync $RUST_SRC_DIR/library/sysroot/Cargo.lock \
    cargo-registry

chown -R "$HOST_USER" cargo-registry
find ../../inputs/crates -mindepth 1 -delete
find cargo-registry -mindepth 1 -maxdepth 1 -exec mv {} ../../inputs/crates \;
find . -mindepth 1 -delete
