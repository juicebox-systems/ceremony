#!/bin/sh

# This script is installed at '/usr/local/bin/ceremony' in the boot DVD's
# squashfs filesystem. It compiles the ceremony tool from source if needed,
# then execs that.

set -eu

(
    cd /root/ceremony/tool
    if [ ! -e target/release/ceremony ]; then
        cargo build --frozen --release
    fi
)

exec /root/ceremony/tool/target/release/ceremony "$@"
