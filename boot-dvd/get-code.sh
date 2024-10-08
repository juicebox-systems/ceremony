#!/bin/sh

# This script is called from the host to download and package source code, as
# an input to the image builder. It also copies in the '../tool' code and
# the vendor-provided feature activation files from './features'.

set -eux

# cd to this directory
cd -P -- "$(dirname -- "$0")"

pack() {
    # See https://reproducible-builds.org/docs/archives/ for relevant flags to
    # make the tarball reproducible.
    tar \
        --create \
        --exclude-vcs \
        --group=0 \
        --mtime='2023-01-01 00:00Z' \
        --numeric-owner \
        --owner=0 \
        --pax-option='exthdr.name=%d/PaxHeaders/%f,delete=atime,delete=ctime' \
        --sort=name \
        "$@"
}

internal/make-cache-dir.sh inputs target

rm -rf inputs/features
mkdir inputs/features
cp features/*.txt inputs/features

rm -rf target/code
mkdir target/code
cd target/code

if ! git diff --exit-code --stat HEAD -- ../../../tool; then
    echo "ERROR: commit your local changes to the ceremony tool first"
    exit 1
fi
mkdir ceremony
git --work-tree ceremony restore --source HEAD -- tool
pack --file ../../inputs/ceremony-tool.tar ceremony

if [ -f ../../inputs/juicebox-hsm-realm.tar ]; then
    echo "WARNING: inputs/juicebox-hsm-realm.tar exists, not cloning juicebox-hsm-realm"
else
    GIT_SHA1=$(sed -En 's/^juicebox_hsm_realm_git_sha1=([a-f0-9]{40})$/\1/p' ../../internal/hashes.txt)

    # See https://stackoverflow.com/questions/31278902/how-to-shallow-clone-a-specific-commit-with-depth-1
    mkdir juicebox-hsm-realm
    cd juicebox-hsm-realm
    git init --initial-branch=main
    # TODO: replace with anonymous https://github.com/juicebox-systems/juicebox-hsm-realm.git
    git remote add origin git@github.com:juicebox-systems/juicebox-hsm-realm.git
    git fetch --depth 1 origin "$GIT_SHA1"
    git checkout FETCH_HEAD
    git submodule update --init --depth 1 --single-branch -- \
        ciborium gcp_auth sdk
    cd ..

    # With a tag or branch name, this would be a bit easier:
    #git clone \
    #    --branch 'mybranch' \
    #    --depth 1 \
    #    --recurse-submodules=ciborium \
    #    --recurse-submodules=gcp_auth \
    #    --recurse-submodules=sdk \
    #    --shallow-submodules \
    #    --single-branch \
    #    git@github.com:juicebox-systems/juicebox-hsm-realm.git

    pack --file ../../inputs/juicebox-hsm-realm.tar juicebox-hsm-realm
fi
