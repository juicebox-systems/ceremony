# Ceremony Boot DVD

This directory contains scripts to build the boot DVD image for the key
ceremony. It's split into two stages:

1. Downloading inputs, such as source OS packages, code, and dependencies.
2. Building the image within a Docker environment that has no network access.

Both stages require Docker, and the second stage requires a privileged Docker
container. To install Docker on Debian:

```sh
sudo apt install docker.io
```

## Collect Inputs

```sh
./get-debs.sh
./get-rust.sh
./get-code.sh
./get-crates.sh
```

While `get-debs.sh`, `get-rust.sh` and `get-code.sh` can be done in any order,
`get-crates.sh` depends on both `rust` and `code`.

The results will be placed into an `inputs` directory. If you need the scripts
to recreate those files, you may need to manually delete the files first.

To verify the checksums for the `inputs` directory:

```sh
find ./inputs -type f | LC_ALL=C sort | xargs sha256sum | diff -u sha256sum.inputs.txt -
```

The `build.sh` script does this automatically. This method is preferable over
using `sha256sum -c` because it'll catch any new, unexpected files.


## Build a Bootable ISO Image

Run the following (requires a privileged Docker container):

```sh
./build.sh
```

The build takes about 150 seconds on a modern laptop. At the end, it compares
the ISO's hash with `sha256sum.output.txt`.

## Test in a Virtual Machine (on Linux)

Install KVM-QEMU:

```sh
sudo apt install qemu-system-x86 ovmf
```

Then run:

```sh
kvm \
    -bios /usr/share/ovmf/OVMF.fd \
    -cdrom target/live-build/ceremony-boot-amd64.iso \
    -m 8g \
    -nic none \
    -smp 2
```

You can drop the `-nic` line to add a virtual network interface, and adjust the
memory (`-m`) and number of vCPUs (`-smp`) based on available resources. Note
that some of the ceremony steps require significant memory (since there is no
writable disk), and the ceremony desktop has 12 GB of RAM.

Other `kvm` options may be useful:

- To use a filesystem image as a "pseudo-Windows" disk, add this after the
  `-cdrom` option:

  ```
  -drive file=target/pseudo-win.img -snapshot
  ```

- To trace the accesses to the block device(s), add:

  ```
  -trace 'blk_*'
  ```

## Burn to a DVD (on Linux)

Install Xorriso:

```sh
sudo apt install xorriso
```

Then run:

```sh
./burn.sh target/live-build/ceremony-boot-amd64.iso
```

Label the disc "Juicebox Ceremony Boot DVD", along with the local date and time
and an identifying prefix of the SHA-256 hash of the ISO file.
