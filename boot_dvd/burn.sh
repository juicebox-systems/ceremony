#!/bin/sh

# This script is run from the host to burn an ISO image to a blank DVD in the
# computer's first optical drive. It requires 'xorriso' to be installed. Pass
# the path to the ISO image as the first argument.

set -eu

if [ $# -ne 1 ]; then
    echo "Usage: $0 ISO-FILE"
    exit 1
fi

set -x

xorriso \
    -as cdrecord \
    -v \
    -eject \
    -sao \
    dev=/dev/sr0 \
    "$1"
