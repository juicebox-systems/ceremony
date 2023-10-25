#!/bin/sh

# This script is meant to run on the host or in CI to verify that
# 'internal/entrust.ps1' agrees with '../vendor-dvd/sha256sum.txt'. It'd be
# especially easy to forget to update 'entrust.ps1' since it requires manual
# testing (Windows) and has the hashes in uppercase.

set -eux

# cd to this directory
cd -P -- "$(dirname -- "$0")"

# This assigns $CODESAFE, $FIRMWARE, and $SECWORLD with the hashes expected in
# 'entrust.ps1', converted to lowercase hex.
eval "$(sed -En 'N; s/^ *path='\''E:\\(CODESAFE|FIRMWARE|SECWORLD).ZIP'\''\n *hash='\''([A-F0-9]{64})'\''$/\1=\L\2\E/p' internal/entrust.ps1)"

diff -u ../vendor-dvd/sha256sum.inputs.txt - <<END
$CODESAFE  ./inputs/Codesafe_Lin64-13.4.3.iso.zip
$SECWORLD  ./inputs/SecWorld_Lin64-13.4.4.iso.zip
$FIRMWARE  ./inputs/nShield_HSM_Firmware-13.4.4.iso.zip
END
