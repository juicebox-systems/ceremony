#!/bin/sh

# This script is called from inside a Docker container to run tests requiring
# the vendor's Codesafe archive. It is normally run by 'test-codesafe.sh'.
#
# It verifies that the build outputs hash the same as '../internal/hashes.txt'
# and runs the vendor-specific unit tests.

set -eu

# cd to boot-dvd directory
cd -P -- "$(dirname -- "$0")"/..

set -x
ceremony vendor install codesafe
ceremony build init
ceremony build hsm
set +x

entrust_init_output=$(ceremony build init 2>/dev/null)
entrust_hsm_elf_output=$(ceremony build hsm 2>/dev/null)

bip39_pattern='/^as BIP-39 mnemonic:$/{ n; N; N; N; N; N; s/\s+/ /g; s/^ // p }'
sha256_pattern='s/^SHA-256: ([a-f0-9]{64})$/\1/p'

entrust_hsm_elf_bip39=$(echo "$entrust_hsm_elf_output" | sed -En "$bip39_pattern")
entrust_hsm_elf_sha256=$(echo "$entrust_hsm_elf_output" | sed -En "$sha256_pattern")
entrust_init_bip39=$(echo "$entrust_init_output" | sed -En "$bip39_pattern")
entrust_init_sha256=$(echo "$entrust_init_output" | sed -En "$sha256_pattern")
juicebox_hsm_realm_git_sha1=$(sed -En 's/^juicebox_hsm_realm_git_sha1=([a-f0-9]{40})$/\1/p' internal/hashes.txt)

set -x
diff -u internal/hashes.txt - <<END
entrust_hsm_elf_bip39=$entrust_hsm_elf_bip39
entrust_hsm_elf_sha256=$entrust_hsm_elf_sha256
entrust_init_bip39=$entrust_init_bip39
entrust_init_sha256=$entrust_init_sha256
juicebox_hsm_realm_git_sha1=$juicebox_hsm_realm_git_sha1
END

cd /root/juicebox-hsm-realm
cargo test --package 'entrust*'
