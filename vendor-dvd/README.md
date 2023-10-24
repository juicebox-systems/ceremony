## Ceremony Vendor DVD

This directory contains scripts to build the vendor DVD image for the key
ceremony. To use this, you must get the files listed in `sha256sum.inputs.txt`
from Entrust and supply them in the `inputs` directory.

To allow the ISO image to be easy to inspect, this uses a primitive format,
which restricts filenames severely. The files are written as `CODESAFE.ZIP`,
`FIRMWARE.ZIP`, and `SECWORLD.ZIP`. Note: Linux will map all filenames and
extensions to lowercase when mounting this image, but Windows will keep them
uppercase.

## Create the ISO image

This step requires Docker to ensure a reproducible image. Run:

```sh
make-iso.sh
```

## Burn to a DVD (on Linux)

Install Xorriso:

```sh
sudo apt install xorriso
```

Then run:

```sh
../boot-dvd/burn.sh target/vendor.iso
```

Label the disc "Juicebox Ceremony Vendor DVD", along with the local date and
time and an identifying prefix of the SHA-256 hash of the ISO file.
