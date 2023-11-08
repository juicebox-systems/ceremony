#!/bin/sh

set -eu

# cd to this directory
cd -P -- "$(dirname -- "$0")"

# Make sure the output file exists, so it can be bind-mounted below and won't
# end up with an owner of root.
if ! [ -f ceremony.pdf ]; then
    true > ceremony.pdf
fi

# Use typst v0.8.0, since v0.9.0's output is not deterministic. See
# https://github.com/typst/typst/issues/2536
image='ghcr.io/typst/typst:v0.8.0'

echo "Starting Docker container ($image)"
docker run \
    --interactive \
    --net none \
    --rm \
    --volume "$PWD/..":/ceremony:ro \
    --volume "$PWD/ceremony.pdf":/ceremony/instructions/ceremony.pdf \
    --workdir /ceremony/instructions \
    "$image" \
    sh -x -c 'typst compile --root .. ceremony.typ'

sha256sum ceremony.pdf
