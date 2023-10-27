#!/usr/bin/env python3

# This script is meant to run on the host or in CI to verify that
# 'internal/entrust.ps1' agrees with '../vendor-dvd/sha256sum.txt'. It'd be
# especially easy to forget to update 'entrust.ps1' since it requires manual
# testing (Windows) and has the hashes in uppercase.

import os
from pprint import pprint
import re
import sys

# cd to this directory
os.chdir(os.path.dirname(os.path.abspath(sys.argv[0])))

ps1_hashes = {
    name: hash.lower()
    for (name, hash) in re.findall(
        r"\spath='E:\\([^']+)',?\s*hash='([A-F0-9]{64})'",
        open("internal/entrust.ps1").read(),
    )
}

print("entrust.ps1 hashes:")
pprint(ps1_hashes)
print()


def path_to_name(path):
    if path.endswith(".iso.zip"):
        if path.startswith("./inputs/Codesafe"):
            return "CODESAFE.ZIP"
        elif path.startswith("./inputs/SecWorld"):
            return "SECWORLD.ZIP"
        elif path.startswith("./inputs/nShield_HSM_Firmware"):
            return "FIRMWARE.ZIP"
    return path


dvd_hashes = {
    path_to_name(path): hash
    for (hash, path) in (
        line.split() for line in open("../vendor-dvd/sha256sum.inputs.txt")
    )
}

print("Vendor DVD hashes:")
pprint(dvd_hashes)
print()

assert ps1_hashes == dvd_hashes
print("OK")
