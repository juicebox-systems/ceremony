#!/bin/sh

# This script is called from inside the Docker container to build a new boot
# ISO image. It expects several bind mounts, as set up by 'build.sh'.
#
# This builds an image using the Debian Live tools. See
# https://live-team.pages.debian.net/live-manual/ for documentation.

set -eux

# cd to the ceremony directory
cd -P -- "$(dirname -- "$0")"/..
ceremony_dir=$(pwd)

. ./internal/vars.sh

# Quiet down complains from debconf about `dialog` being unavailable.
export DEBIAN_FRONTEND=noninteractive

# Set fake timestamps in the image for reproducibility.
# See https://reproducible-builds.org/docs/source-date-epoch/
SOURCE_DATE_EPOCH=$(date -u -d 2023-01-01 +'%s')
export SOURCE_DATE_EPOCH

cd /etc/apt/sources.list.d
if [ -f debian.sources ]; then
    # Surprisingly, 'mv' fails here for Diego:
    #
    #     mv: cannot move 'debian.sources' to a subdirectory of itself, 'debian.sources.disabled'
    #
    # It's probably related to being unable to rename atomically from a Docker
    # layer into an overlay, when running with the overlay2 "storage driver"
    # backed by a ZFS filesystem.
    #
    # I couldn't repro this under ext4, but on my laptop, I could repro this
    # with a simple 'docker run -it --rm debian:bookworm' and run it under
    # strace. The same error happens with other files, too. 'mv' calls
    # 'renameat2()' with RENAME_NOREPLACE, and gets back EINVAL. Maybe it
    # should pass RENAME_WHITEOUT, but it doesn't. If I create a new file in
    # the same directory, that can be moved successfully ('renameat2()' with
    # RENAME_NOREPLACE returns 0).
    #
    # It's a mystery how this issue doesn't come up more often -- or maybe it
    # does and the errors are silently ignored.
    cp -a debian.sources debian.sources.disabled
    rm debian.sources
fi

# Use the packages from 'inputs/apt' for better reproducibility and to allow
# this container to run without a network.
cat > local.list <<END
deb file:$ceremony_dir/inputs/apt/debian bookworm main
deb file:$ceremony_dir/inputs/apt/debian bookworm-updates main
deb file:$ceremony_dir/inputs/apt/debian-security bookworm-security main
END

cd "$ceremony_dir/target/live-build"
find . -mindepth 1 -delete

apt update -o 'APT::Update::Error-Mode=any'

# Python is used to serve the apt files over HTTP, which is convenient for the
# chroot. It also logs all the URL accesses, so we can make sure we don't have
# extra files in 'inputs/apt' (checked below). It's OK that the installation of
# python3 itself isn't logged here because it's installed again for the chroot
# later.
apt install --no-install-recommends --yes python3

python3 -m http.server -d ../../inputs/apt --bind 127.0.0.1 80 2>http.log &
apt_http_pid=$!

cat > /etc/apt/sources.list.d/local.list <<'END'
deb http://127.0.0.1/debian bookworm main
deb http://127.0.0.1/debian bookworm-updates main
deb http://127.0.0.1/debian-security bookworm-security main
END

# It can take Python a little time to start up before 'apt update' succeeds.
# Putting the 'apt update' in a retry loop works, but it can be a little
# confusing to see errors in the output. A quick sleep beforehand is enough to
# avoid that most of the time.
sleep 1
i=0
while ! apt update -o 'APT::Update::Error-Mode=any'; do
    i=$(( i + 1 ))
    if [ $i -eq 10 ]; then
        echo 'ERROR: Giving up'
        exit 1
    fi
    echo 'WARNING: Retrying in 1 second...'
    sleep 1
done

apt upgrade --no-install-recommends --yes

# cpio is needed to include files in the binary target.
apt install --no-install-recommends --yes \
    cpio \
    live-build \
    time

# Notes:
# - Use a local HTTP server (spawned below) to serve deb files from 'inputs/apt'.
# - Setting '--apt-indices' to false causes the chroot's APT index files to be
#   deleted, but not before they're downloaded and updated. To avoid
#   downloading those from 'deb.debian.org', set '--mirror-binary' and
#   '--mirror-binary-security' to localhost. The boot DVD shouldn't be
#   connected to the network anyway, so its APT configuration doesn't matter.
# - In '--apt-options', expired release files are allowed to enable building
#   from an old snapshot.
# - In '--bootappend-live', the components listed are a subset of the default,
#   stripped down since the live image runs as 'root' and doesn't run X.
lb config \
    --apt-indices false \
    --apt-options '--yes -o Acquire::Check-Valid-Until=false -o Acquire::Languages=none' \
    --apt-recommends false \
    --apt-source-archives false \
    --architecture amd64 \
    --binary-image iso \
    --bootappend-live 'boot=live username=root hostname=ceremony components=nss-systemd,debconf,hostname,locales,tzdata,keyboard-configuration,util-linux,login,hooks' \
    --bootloaders grub-efi \
    --cache false \
    --checksums sha256 \
    --chroot-squashfs-compression-type zstd \
    --debootstrap-options '--verbose' \
    --debug \
    --distribution $DEBIAN_CODENAME \
    --distribution-binary $DEBIAN_CODENAME \
    --distribution-chroot $DEBIAN_CODENAME \
    --firmware-binary false \
    --firmware-chroot false \
    --image-name ceremony-boot \
    --mirror-binary 'http://127.0.0.1/debian/' \
    --mirror-binary-security 'http://127.0.0.1/debian-security/' \
    --mirror-bootstrap 'http://127.0.0.1/debian/' \
    --mirror-chroot-security 'http://127.0.0.1/debian-security/' \
    --iso-publisher 'Juicebox' \
    --utc-time true \
    --verbose \
    --zsync false

# Now we copy and modify files inside `config`. Some of these configure the
# build, some are executed during the build, and some are copied into the
# resulting image. The following are sorted by their intermediate destination
# path.

# The Rust installation copies a file to /usr/local/lib/libLLVM-*.so that
# contains some runs of zeroes. Somehow, the resulting file varies in
# sparseness. `cp` defaults to using an apparently nondeterministic heuristic
# with `--sparse=auto`. Then, mksquashfs tries to preserve the sparseness by
# default, making the squashfs image nondeterministic.
#
# Diego was able to reproduce this under Docker running with the overlayfs2
# driver atop either ZFS or ext4. The problem does seems to be more frequent on
# ZFS, where the file's sparseness can vary depending on how many times you
# check its metadata.
#
# Disabling sparse files shouldn't cause any trouble because:
# - The LLVM file only has long runs of zeros for about 3.5% of the file,
# - It's compressed anyway in the squashfs image, and
# - It's the only sparse file on the entire filesystem (across 2 runs).
grep --invert-match --quiet --recursive MKSQUASHFS_OPTIONS config
echo 'MKSQUASHFS_OPTIONS="-no-sparse"' >> config/binary

# Install Rust in the resulting image.
cp -av ../../internal/install-rust.sh \
    config/hooks/normal/6000-rust.hook.chroot

# Boot into tmux since the kernel's fbcon no longer supports scrollback.
cat > config/hooks/normal/6000-tmux.hook.chroot <<'END'
#!/bin/sh
set -eux
chsh --shell /usr/bin/tmux root
END
chmod +x config/hooks/normal/6000-tmux.hook.chroot

# Copy 'entrust.ps1' to the ISO, outside the squashfs filesystem. This makes it
# easy to access from Windows.
cp -av ../../internal/entrust.ps1 \
    config/includes.binary/

# Copy 'init-premount.sh' where it'll be placed into the initramfs.
mkdir -p config/includes.chroot/usr/share/initramfs-tools/scripts/init-premount/
cp -av ../../internal/init-premount.sh \
    config/includes.chroot/usr/share/initramfs-tools/scripts/init-premount/wincache

# Copy 'run-tool.sh' as 'ceremony' in the $PATH on the squashfs filesystem.
mkdir -p config/includes.chroot/usr/local/bin
cp -av ../../internal/run-tool.sh \
    config/includes.chroot/usr/local/bin/ceremony

# Copy various things into /root/ on the squashfs filesystem.
mkdir -p config/includes.chroot/root/.cargo
cat > config/includes.chroot/root/.cargo/config.toml <<'END'
[source.crates-io]
registry = 'sparse+https://index.crates.io/'
replace-with = 'local-registry'

[source.local-registry]
local-registry = 'crates'
END

cp -av ../../internal/tmux.conf config/includes.chroot/root/.tmux.conf

# Note: the install-rust.sh hook will read and delete some of these files
# later, including vars.sh.
cp -a \
    ../../inputs/crates \
    ../../inputs/rust-$RUST_VERSION-x86_64-unknown-linux-gnu.tar.xz \
    ../../inputs/rust-src-$RUST_VERSION.tar.xz \
    ../../internal/vars.sh \
    config/includes.chroot/root/

tar -C config/includes.chroot/root/ -xf ../../inputs/ceremony-tool.tar
tar -C config/includes.chroot/root/ -xf ../../inputs/juicebox-hsm-realm.tar

# TODO: copy in feature certificate files

# Necessary packages to include in the live image. Notes:
# - bindgen requires libclang.
# - Building the HSM driver requires kernel headers.
# - zstd avoids some warnings when generating initrd.
cat > config/package-lists/juicebox.list.chroot <<'END'
gcc
libc6-dev
libclang-dev
linux-headers-amd64
make
ntfs-3g
tmux
unzip
xorriso
xz-utils
zstd
END

# Helpful packages to include in the live image. Notes:
# - bsdextrautils contains hexdump.
# - pciutils contains lspci.
# - Python could be useful if we got into deep trouble during the ceremony.
# - usbutils contains lsusb.
cat > config/package-lists/utilities.list.chroot <<'END'
bsdextrautils
git
lsof
pciutils
pv
python3
strace
time
tree
usbutils
vim
xxd
END

# Run live-build.
/usr/bin/time -p lb build

kill $apt_http_pid

set -x

echo
echo 'Successfully built the boot DVD ISO'

(
    cd ../../
    ls -sh target/live-build/ceremony-boot-amd64.iso
    sha256sum ./target/live-build/ceremony-boot-amd64.iso
)

# Check that all the 'inputs/apt' files were actually needed.
(
    cd ../../inputs/apt
    find . -type f -printf '%P\n'
) | LC_ALL=C sort > apt-all.txt

sed -En 's!^.* "GET /(.*) HTTP/1\.1" 200 -$!\1!p' http.log |
    sed -E 's/%2b/+/g; s/%3a/:/g; s/%7e/~/g' |
    LC_ALL=C sort -u \
    > apt-used.txt

diff -u apt-all.txt apt-used.txt
