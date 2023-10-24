#!/bin/sh

# This script is used to create a cache directory with an appropriate
# CACHEDIR.TAG file. This is useful for preventing backups, etc.
#
# Pass the path(s) to the new cache directories as arguments.

set -eu

mkdir -p "$@"

that=This
for dir in "$@"; do
    cat > "$dir/CACHEDIR.TAG" <<END
Signature: 8a477f597d28d172789f06886806bc55
# $that file is a cache directory tag created by ceremony scripts.
# For information about cache directory tags, see:
# http://www.brynosaurus.com/cachedir/
END
done
