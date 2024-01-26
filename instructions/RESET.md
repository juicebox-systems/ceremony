This file describes how to get things back into a clean slate so that you can
test the instructions.

## Wipe the Smartcards

```sh
ceremony smartcard erase # OCS
ceremony smartcard erase # ACS
```

## Restore the NVMe Disk

Connect the computer to a network and boot a standard live CD/DVD/USB or the
boot DVD. Set up the network, and then run:

```sh
GITHUB_USERNAME= # fill this in
apt update
apt install ca-certificates curl iotop openssh-server zstd
curl https://github.com/$GITHUB_USERNAME.keys > .ssh/authorized_keys
ip addr # record IP address
umount /run/win
iotop --only
```

On another computer:

```sh
LENOVO_IP= # fill this in
pv lenovo-windows-disk.img.zst | ssh -C root@$LENOVO_IP 'zstd --decompress --stdout | dd bs=1M of=/dev/nvme0n1'
```

This takes about 30 minutes. The `pv` output will appear to stall towards the
end of the file, while the ceremony computer writes out a bunch of zeros.

## Reset the UEFI Settings

Restore the default settings.

Set the hardware time to US Mountain time.

Reset the boot priority manually because it doesn't get reset with restoring
default settings.

## Rebuild and Pack Up the Computer

## Burn New DVDs

See `../boot-dvd/README.md` and `../vendor-dvd/README.md`.

## Print New Instructions

Print `ceremony.pdf`.
