#!/bin/sh

# This script is called from the host to download the Debian packages and
# indexes, as an input to the image builder.
#
# Ideally we'd be able to point the image builder to snapshots.debian.org and
# things would be fast and reproducible. However, as of 2023, that service is
# slow to access. Requests often time out, and they can allegedly be
# rate-limited as well. This script creates a local cache of just the files
# needed to package the image.
#
# Unless $SNAPSHOT_SERVER_ONLY is nonempty, this script downloads most files
# from deb.debian.org to save time, for the deb files that are still present
# there. As the snapshot ages, deb.debian.org will have fewer of the
# snapshotted debs, and eventually the entire Debian release will be archived.
# This script always pulls the index files from the snapshots.debian.org
# service, which include the expected hashes for the deb files.

set -eu

# cd to this directory
cd -P -- "$(dirname -- "$0")"

internal/make-cache-dir.sh inputs

fetch() {
    if [ -z "$3" ]; then
        return 0
    fi
    path="inputs/apt/$1/$3"
    if [ -f "$path" ]; then
        return 0
    fi
    url="$2/$3"

    echo "Fetching $url"
    echo "to $path"
    mkdir -p "$(dirname "$path")"

    # Download to a temporary file since curl can leave behind partial files on
    # timeouts or interrupts. The option '--remove-on-error' was added in curl
    # version 7.83 to address this, but Debian 11 (Bullseye) shipped with 7.74.

    if curl \
        --connect-timeout 10 \
        --fail \
        --max-time 60 \
        --output "$path.tmp" \
        --retry 5 \
        --retry-delay 5 \
        "$url"; then
        echo
        mv "$path.tmp" "$path"
        return 0
    else
        echo
        rm -f "$path.tmp"
        return 1
    fi
}

DEBIAN_ROLLING='https://deb.debian.org/debian'
DEBIAN_SECURITY_ROLLING='https://deb.debian.org/debian-security'

DEBIAN_SNAPSHOT='https://snapshot.debian.org/archive/debian/20231001T025741Z'
DEBIAN_SECURITY_SNAPSHOT='https://snapshot.debian.org/archive/debian-security/20231001T104447Z'

fetch debian "$DEBIAN_SNAPSHOT" dists/bookworm/InRelease
# debootstrap doesn't use the newer 'Packages.xz' format yet.
fetch debian "$DEBIAN_SNAPSHOT" dists/bookworm/main/binary-amd64/Packages.gz

fetch debian "$DEBIAN_SNAPSHOT" dists/bookworm-updates/InRelease
fetch debian "$DEBIAN_SNAPSHOT" dists/bookworm-updates/main/binary-amd64/Packages.xz

fetch debian-security "$DEBIAN_SECURITY_SNAPSHOT" dists/bookworm-security/InRelease
fetch debian-security "$DEBIAN_SECURITY_SNAPSHOT" dists/bookworm-security/main/binary-amd64/Packages.xz

# The file lists below were built by iteratively:
# - building the image until it fails,
# - extracting paths from URLs in the output and percent-decoding them,
# - copying that below, and
# - fetching the new debs.
#
# When there's a new snapshot with updated packages, these steps can be
# repeated, adding to the existing lists. After the main build runs, it will
# report if any apt files were unused, so you can delete unnecessary files from
# the lists.

# Get the debian (not debian-security) packages.
while read -r p; do
    if [ -n "${SNAPSHOT_SERVER_ONLY:-}" ]; then
        false
    else
        fetch debian "$DEBIAN_ROLLING" "$p"
    fi || fetch debian "$DEBIAN_SNAPSHOT" "$p"
done <<'END'
pool/main/a/acl/libacl1_2.3.1-3_amd64.deb
pool/main/a/adduser/adduser_3.134_all.deb
pool/main/a/apparmor/libapparmor1_3.0.8-3_amd64.deb
pool/main/a/apt/apt-utils_2.6.1_amd64.deb
pool/main/a/apt/apt_2.6.1_amd64.deb
pool/main/a/apt/libapt-pkg6.0_2.6.1_amd64.deb
pool/main/a/argon2/libargon2-1_0~20171227-0.3+deb12u1_amd64.deb
pool/main/a/attr/libattr1_2.5.1-4_amd64.deb
pool/main/a/audit/libaudit-common_3.0.9-1_all.deb
pool/main/a/audit/libaudit1_3.0.9-1_amd64.deb
pool/main/b/base-files/base-files_12.4+deb12u1_amd64.deb
pool/main/b/base-passwd/base-passwd_3.6.1_amd64.deb
pool/main/b/bash/bash_5.2.15-2+b2_amd64.deb
pool/main/b/binutils/binutils-common_2.40-2_amd64.deb
pool/main/b/binutils/binutils-x86-64-linux-gnu_2.40-2_amd64.deb
pool/main/b/binutils/binutils_2.40-2_amd64.deb
pool/main/b/binutils/libbinutils_2.40-2_amd64.deb
pool/main/b/binutils/libctf-nobfd0_2.40-2_amd64.deb
pool/main/b/binutils/libctf0_2.40-2_amd64.deb
pool/main/b/binutils/libgprofng0_2.40-2_amd64.deb
pool/main/b/brotli/libbrotli1_1.0.9-2+b6_amd64.deb
pool/main/b/busybox/busybox_1.35.0-4+b3_amd64.deb
pool/main/b/bzip2/libbz2-1.0_1.0.8-5+b1_amd64.deb
pool/main/c/cdebconf/libdebconfclient0_0.270_amd64.deb
pool/main/c/coreutils/coreutils_9.1-1_amd64.deb
pool/main/c/cpio/cpio_2.13+dfsg-7.1_amd64.deb
pool/main/c/cron/cron-daemon-common_3.0pl1-162_all.deb
pool/main/c/cron/cron_3.0pl1-162_amd64.deb
pool/main/c/cryptsetup/libcryptsetup12_2.6.1-4~deb12u1_amd64.deb
pool/main/c/cyrus-sasl2/libsasl2-2_2.1.28+dfsg-10_amd64.deb
pool/main/c/cyrus-sasl2/libsasl2-modules-db_2.1.28+dfsg-10_amd64.deb
pool/main/d/dash/dash_0.5.12-2_amd64.deb
pool/main/d/db5.3/libdb5.3_5.3.28+dfsg2-1_amd64.deb
pool/main/d/dctrl-tools/dctrl-tools_2.24-3+b1_amd64.deb
pool/main/d/debconf/debconf-i18n_1.5.82_all.deb
pool/main/d/debconf/debconf_1.5.82_all.deb
pool/main/d/debian-archive-keyring/debian-archive-keyring_2023.3_all.deb
pool/main/d/debianutils/debianutils_5.7-0.4_amd64.deb
pool/main/d/debootstrap/debootstrap_1.0.128+nmu2_all.deb
pool/main/d/diffutils/diffutils_3.8-4_amd64.deb
pool/main/d/dmidecode/dmidecode_3.4-1_amd64.deb
pool/main/d/dosfstools/dosfstools_4.2-1_amd64.deb
pool/main/d/dpkg/dpkg_1.21.22_amd64.deb
pool/main/e/e2fsprogs/e2fsprogs_1.47.0-2_amd64.deb
pool/main/e/e2fsprogs/libcom-err2_1.47.0-2_amd64.deb
pool/main/e/e2fsprogs/libext2fs2_1.47.0-2_amd64.deb
pool/main/e/e2fsprogs/libss2_1.47.0-2_amd64.deb
pool/main/e/e2fsprogs/logsave_1.47.0-2_amd64.deb
pool/main/e/efivar/libefiboot1_37-6_amd64.deb
pool/main/e/efivar/libefivar1_37-6_amd64.deb
pool/main/e/elfutils/libelf1_0.188-2.1_amd64.deb
pool/main/e/expat/libexpat1_2.5.0-1_amd64.deb
pool/main/f/findutils/findutils_4.9.0-4_amd64.deb
pool/main/f/freetype/libfreetype6_2.12.1+dfsg-5_amd64.deb
pool/main/f/fuse/libfuse2_2.9.9-6+b1_amd64.deb
pool/main/f/fuse3/fuse3_3.14.0-4_amd64.deb
pool/main/f/fuse3/libfuse3-3_3.14.0-4_amd64.deb
pool/main/g/gcc-12/cpp-12_12.2.0-14_amd64.deb
pool/main/g/gcc-12/gcc-12-base_12.2.0-14_amd64.deb
pool/main/g/gcc-12/gcc-12_12.2.0-14_amd64.deb
pool/main/g/gcc-12/libasan8_12.2.0-14_amd64.deb
pool/main/g/gcc-12/libatomic1_12.2.0-14_amd64.deb
pool/main/g/gcc-12/libcc1-0_12.2.0-14_amd64.deb
pool/main/g/gcc-12/libgcc-12-dev_12.2.0-14_amd64.deb
pool/main/g/gcc-12/libgcc-s1_12.2.0-14_amd64.deb
pool/main/g/gcc-12/libgomp1_12.2.0-14_amd64.deb
pool/main/g/gcc-12/libitm1_12.2.0-14_amd64.deb
pool/main/g/gcc-12/liblsan0_12.2.0-14_amd64.deb
pool/main/g/gcc-12/libobjc-12-dev_12.2.0-14_amd64.deb
pool/main/g/gcc-12/libobjc4_12.2.0-14_amd64.deb
pool/main/g/gcc-12/libquadmath0_12.2.0-14_amd64.deb
pool/main/g/gcc-12/libstdc++-12-dev_12.2.0-14_amd64.deb
pool/main/g/gcc-12/libstdc++6_12.2.0-14_amd64.deb
pool/main/g/gcc-12/libtsan2_12.2.0-14_amd64.deb
pool/main/g/gcc-12/libubsan1_12.2.0-14_amd64.deb
pool/main/g/gcc-defaults/cpp_12.2.0-3_amd64.deb
pool/main/g/gcc-defaults/gcc_12.2.0-3_amd64.deb
pool/main/g/gdbm/libgdbm-compat4_1.23-3_amd64.deb
pool/main/g/gdbm/libgdbm6_1.23-3_amd64.deb
pool/main/g/gettext/gettext-base_0.21-12_amd64.deb
pool/main/g/git/git-man_2.39.2-1.1_all.deb
pool/main/g/git/git_2.39.2-1.1_amd64.deb
pool/main/g/glibc/libc-bin_2.36-9+deb12u1_amd64.deb
pool/main/g/glibc/libc-dev-bin_2.36-9+deb12u1_amd64.deb
pool/main/g/glibc/libc6-dev_2.36-9+deb12u1_amd64.deb
pool/main/g/glibc/libc6_2.36-9+deb12u1_amd64.deb
pool/main/g/gmp/libgmp10_6.2.1+dfsg1-1.1_amd64.deb
pool/main/g/gnupg2/gpgv_2.2.40-1.1_amd64.deb
pool/main/g/gnutls28/libgnutls30_3.7.9-2_amd64.deb
pool/main/g/gpm/libgpm2_1.20.7-10+b1_amd64.deb
pool/main/g/grep/grep_3.8-5_amd64.deb
pool/main/g/grub-efi-amd64-signed/grub-efi-amd64-signed_1+2.06+13_amd64.deb
pool/main/g/grub2/grub-common_2.06-13_amd64.deb
pool/main/g/grub2/grub-efi-amd64-bin_2.06-13_amd64.deb
pool/main/g/grub2/grub-efi-ia32-bin_2.06-13_amd64.deb
pool/main/g/grub2/grub2-common_2.06-13_amd64.deb
pool/main/g/gzip/gzip_1.12-1_amd64.deb
pool/main/h/hostname/hostname_3.23+nmu1_amd64.deb
pool/main/i/icu/libicu72_72.1-3_amd64.deb
pool/main/i/ifupdown/ifupdown_0.8.41_amd64.deb
pool/main/i/init-system-helpers/init-system-helpers_1.65.2_all.deb
pool/main/i/init-system-helpers/init_1.65.2_amd64.deb
pool/main/i/initramfs-tools/initramfs-tools-core_0.142_all.deb
pool/main/i/initramfs-tools/initramfs-tools_0.142_all.deb
pool/main/i/iproute2/iproute2_6.1.0-3_amd64.deb
pool/main/i/iptables/libip4tc2_1.8.9-2_amd64.deb
pool/main/i/iptables/libxtables12_1.8.9-2_amd64.deb
pool/main/i/iputils/iputils-ping_20221126-1_amd64.deb
pool/main/i/isc-dhcp/isc-dhcp-client_4.4.3-P1-2_amd64.deb
pool/main/i/isc-dhcp/isc-dhcp-common_4.4.3-P1-2_amd64.deb
pool/main/i/isl/libisl23_0.25-1_amd64.deb
pool/main/j/jansson/libjansson4_2.14-2_amd64.deb
pool/main/j/jigit/libjte2_1.22-3_amd64.deb
pool/main/j/json-c/libjson-c5_0.16-2_amd64.deb
pool/main/k/keyutils/libkeyutils1_1.6.3-2_amd64.deb
pool/main/k/klibc/klibc-utils_2.0.12-1_amd64.deb
pool/main/k/klibc/libklibc_2.0.12-1_amd64.deb
pool/main/k/kmod/kmod_30+20221128-1_amd64.deb
pool/main/k/kmod/libkmod2_30+20221128-1_amd64.deb
pool/main/k/krb5/libgssapi-krb5-2_1.20.1-2_amd64.deb
pool/main/k/krb5/libk5crypto3_1.20.1-2_amd64.deb
pool/main/k/krb5/libkrb5-3_1.20.1-2_amd64.deb
pool/main/k/krb5/libkrb5support0_1.20.1-2_amd64.deb
pool/main/l/less/less_590-2_amd64.deb
pool/main/l/linux-base/linux-base_4.9_all.deb
pool/main/l/live-boot/live-boot-initramfs-tools_20230131_all.deb
pool/main/l/live-boot/live-boot_20230131_all.deb
pool/main/l/live-build/live-build_20230502_all.deb
pool/main/l/live-config/live-config-systemd_11.0.3+nmu1_all.deb
pool/main/l/live-config/live-config_11.0.3+nmu1_all.deb
pool/main/l/llvm-defaults/libclang-dev_14.0-55.6_amd64.deb
pool/main/l/llvm-toolchain-14/libclang-14-dev_14.0.6-12_amd64.deb
pool/main/l/llvm-toolchain-14/libclang-common-14-dev_14.0.6-12_all.deb
pool/main/l/llvm-toolchain-14/libclang1-14_14.0.6-12_amd64.deb
pool/main/l/llvm-toolchain-14/libllvm14_14.0.6-12_amd64.deb
pool/main/l/logrotate/logrotate_3.21.0-1_amd64.deb
pool/main/l/lsof/lsof_4.95.0-1_amd64.deb
pool/main/l/lvm2/dmsetup_1.02.185-2_amd64.deb
pool/main/l/lvm2/libdevmapper1.02.1_1.02.185-2_amd64.deb
pool/main/l/lz4/liblz4-1_1.9.4-1_amd64.deb
pool/main/l/lzo2/liblzo2-2_2.10-2_amd64.deb
pool/main/libb/libbpf/libbpf1_1.1.0-1_amd64.deb
pool/main/libb/libbsd/libbsd0_0.11.7-2_amd64.deb
pool/main/libb/libburn/libburn4_1.5.4-1_amd64.deb
pool/main/libc/libcap-ng/libcap-ng0_0.8.3-1+b3_amd64.deb
pool/main/libc/libcap2/libcap2-bin_2.66-4_amd64.deb
pool/main/libc/libcap2/libcap2_2.66-4_amd64.deb
pool/main/libe/libedit/libedit2_3.1-20221030-2_amd64.deb
pool/main/libe/liberror-perl/liberror-perl_0.17029-2_all.deb
pool/main/libe/libevent/libevent-core-2.1-7_2.1.12-stable-8_amd64.deb
pool/main/libf/libffi/libffi8_3.4.4-1_amd64.deb
pool/main/libg/libgc/libgc1_8.2.2-3_amd64.deb
pool/main/libg/libgcrypt20/libgcrypt20_1.10.1-3_amd64.deb
pool/main/libg/libgpg-error/libgpg-error0_1.46-1_amd64.deb
pool/main/libi/libidn2/libidn2-0_2.3.3-1+b1_amd64.deb
pool/main/libi/libisoburn/libisoburn1_1.5.4-4_amd64.deb
pool/main/libi/libisoburn/xorriso_1.5.4-4_amd64.deb
pool/main/libi/libisofs/libisofs6_1.5.4-1_amd64.deb
pool/main/libl/liblocale-gettext-perl/liblocale-gettext-perl_1.07-5_amd64.deb
pool/main/libm/libmd/libmd0_1.0.4-2_amd64.deb
pool/main/libm/libmnl/libmnl0_1.0.4-3_amd64.deb
pool/main/libn/libnftnl/libnftnl11_1.2.4-2_amd64.deb
pool/main/libn/libnsl/libnsl-dev_1.3.0-2_amd64.deb
pool/main/libn/libnsl/libnsl2_1.3.0-2_amd64.deb
pool/main/libp/libpng1.6/libpng16-16_1.6.39-2_amd64.deb
pool/main/libp/libpsl/libpsl5_0.21.2-1_amd64.deb
pool/main/libs/libseccomp/libseccomp2_2.5.4-1+b3_amd64.deb
pool/main/libs/libselinux/libselinux1_3.4-1+b6_amd64.deb
pool/main/libs/libsemanage/libsemanage-common_3.4-1_all.deb
pool/main/libs/libsemanage/libsemanage2_3.4-1+b5_amd64.deb
pool/main/libs/libsepol/libsepol2_3.4-2.1_amd64.deb
pool/main/libs/libsodium/libsodium23_1.0.18-1_amd64.deb
pool/main/libs/libssh2/libssh2-1_1.10.0-3+b1_amd64.deb
pool/main/libt/libtasn1-6/libtasn1-6_4.19.0-2_amd64.deb
pool/main/libt/libtext-charwidth-perl/libtext-charwidth-perl_0.04-11_amd64.deb
pool/main/libt/libtext-iconv-perl/libtext-iconv-perl_1.7-8_amd64.deb
pool/main/libt/libtext-wrapi18n-perl/libtext-wrapi18n-perl_0.06-10_all.deb
pool/main/libt/libtirpc/libtirpc-common_1.3.3+ds-1_all.deb
pool/main/libt/libtirpc/libtirpc-dev_1.3.3+ds-1_amd64.deb
pool/main/libt/libtirpc/libtirpc3_1.3.3+ds-1_amd64.deb
pool/main/libu/libunistring/libunistring2_1.0-2_amd64.deb
pool/main/libu/libunwind/libunwind8_1.6.2-3_amd64.deb
pool/main/libu/libusb-1.0/libusb-1.0-0_1.0.26-1_amd64.deb
pool/main/libu/libutempter/libutempter0_1.2.1-3_amd64.deb
pool/main/libx/libxcrypt/libcrypt-dev_4.4.33-2_amd64.deb
pool/main/libx/libxcrypt/libcrypt1_4.4.33-2_amd64.deb
pool/main/libx/libxml2/libxml2_2.9.14+dfsg-1.3~deb12u1_amd64.deb
pool/main/libz/libzstd/libzstd1_1.5.4+dfsg2-5_amd64.deb
pool/main/libz/libzstd/zstd_1.5.4+dfsg2-5_amd64.deb
pool/main/m/make-dfsg/make_4.3-4.1_amd64.deb
pool/main/m/mawk/mawk_1.3.4.20200120-3.1_amd64.deb
pool/main/m/media-types/media-types_10.0.0_all.deb
pool/main/m/mokutil/mokutil_0.6.0-2_amd64.deb
pool/main/m/mpclib3/libmpc3_1.3.1-1_amd64.deb
pool/main/m/mpfr4/libmpfr6_4.2.0-1_amd64.deb
pool/main/m/mtools/mtools_4.0.33-1+really4.0.32-1_amd64.deb
pool/main/n/nano/nano_7.2-1_amd64.deb
pool/main/n/ncurses/libncursesw6_6.4-4_amd64.deb
pool/main/n/ncurses/libtinfo6_6.4-4_amd64.deb
pool/main/n/ncurses/ncurses-base_6.4-4_all.deb
pool/main/n/ncurses/ncurses-bin_6.4-4_amd64.deb
pool/main/n/netbase/netbase_6.4_all.deb
pool/main/n/nettle/libhogweed6_3.8.1-2_amd64.deb
pool/main/n/nettle/libnettle8_3.8.1-2_amd64.deb
pool/main/n/newt/libnewt0.52_0.52.23-1+b1_amd64.deb
pool/main/n/newt/whiptail_0.52.23-1+b1_amd64.deb
pool/main/n/nftables/libnftables1_1.0.6-2+deb12u1_amd64.deb
pool/main/n/nftables/nftables_1.0.6-2+deb12u1_amd64.deb
pool/main/n/nghttp2/libnghttp2-14_1.52.0-1_amd64.deb
pool/main/n/ntfs-3g/libntfs-3g89_2022.10.3-1+b1_amd64.deb
pool/main/n/ntfs-3g/ntfs-3g_2022.10.3-1+b1_amd64.deb
pool/main/o/openldap/libldap-2.5-0_2.5.13+dfsg-5_amd64.deb
pool/main/o/openssl/libssl3_3.0.9-1_amd64.deb
pool/main/p/p11-kit/libp11-kit0_0.24.1-2_amd64.deb
pool/main/p/pam/libpam-modules-bin_1.5.2-6_amd64.deb
pool/main/p/pam/libpam-modules_1.5.2-6_amd64.deb
pool/main/p/pam/libpam-runtime_1.5.2-6_all.deb
pool/main/p/pam/libpam0g_1.5.2-6_amd64.deb
pool/main/p/pci.ids/pci.ids_0.0~2023.04.11-1_all.deb
pool/main/p/pciutils/libpci3_3.9.0-4_amd64.deb
pool/main/p/pciutils/pciutils_3.9.0-4_amd64.deb
pool/main/p/pcre2/libpcre2-8-0_10.42-1_amd64.deb
pool/main/p/perl/libperl5.36_5.36.0-7_amd64.deb
pool/main/p/perl/perl-base_5.36.0-7_amd64.deb
pool/main/p/perl/perl-modules-5.36_5.36.0-7_all.deb
pool/main/p/perl/perl_5.36.0-7_amd64.deb
pool/main/p/popt/libpopt0_1.19+dfsg-1_amd64.deb
pool/main/p/procps/libproc2-0_4.0.2-3_amd64.deb
pool/main/p/procps/procps_4.0.2-3_amd64.deb
pool/main/p/pv/pv_1.6.20-1_amd64.deb
pool/main/p/python3-defaults/libpython3-stdlib_3.11.2-1+b1_amd64.deb
pool/main/p/python3-defaults/python3-minimal_3.11.2-1+b1_amd64.deb
pool/main/p/python3-defaults/python3_3.11.2-1+b1_amd64.deb
pool/main/p/python3.11/libpython3.11-minimal_3.11.2-6_amd64.deb
pool/main/p/python3.11/libpython3.11-stdlib_3.11.2-6_amd64.deb
pool/main/p/python3.11/python3.11-minimal_3.11.2-6_amd64.deb
pool/main/p/python3.11/python3.11_3.11.2-6_amd64.deb
pool/main/r/readline/libreadline8_8.2-1.3_amd64.deb
pool/main/r/readline/readline-common_8.2-1.3_all.deb
pool/main/r/rpcsvc-proto/rpcsvc-proto_1.4.3-1_amd64.deb
pool/main/r/rtmpdump/librtmp1_2.4+20151223.gitfa8646d.1-2+b2_amd64.deb
pool/main/s/sed/sed_4.9-1_amd64.deb
pool/main/s/sensible-utils/sensible-utils_0.0.17+nmu1_all.deb
pool/main/s/shadow/login_4.13+dfsg1-1+b1_amd64.deb
pool/main/s/shadow/passwd_4.13+dfsg1-1+b1_amd64.deb
pool/main/s/shim-helpers-amd64-signed/shim-helpers-amd64-signed_1+15.7+1_amd64.deb
pool/main/s/shim-signed/shim-signed-common_1.39+15.7-1_all.deb
pool/main/s/shim-signed/shim-signed_1.39+15.7-1_amd64.deb
pool/main/s/shim/shim-unsigned_15.7-1_amd64.deb
pool/main/s/slang2/libslang2_2.3.3-3_amd64.deb
pool/main/s/sqlite3/libsqlite3-0_3.40.1-2_amd64.deb
pool/main/s/squashfs-tools/squashfs-tools_4.5.1-1_amd64.deb
pool/main/s/strace/strace_6.1-0.1_amd64.deb
pool/main/s/syslinux/isolinux_6.04~git20190206.bf6db5b4+dfsg1-3_all.deb
pool/main/s/systemd/libsystemd-shared_252.12-1~deb12u1_amd64.deb
pool/main/s/systemd/libsystemd0_252.12-1~deb12u1_amd64.deb
pool/main/s/systemd/libudev1_252.12-1~deb12u1_amd64.deb
pool/main/s/systemd/systemd-sysv_252.12-1~deb12u1_amd64.deb
pool/main/s/systemd/systemd_252.12-1~deb12u1_amd64.deb
pool/main/s/systemd/udev_252.12-1~deb12u1_amd64.deb
pool/main/s/sysvinit/sysvinit-utils_3.06-4_amd64.deb
pool/main/t/tar/tar_1.34+dfsg-1.2_amd64.deb
pool/main/t/tasksel/tasksel-data_3.73_all.deb
pool/main/t/tasksel/tasksel_3.73_all.deb
pool/main/t/time/time_1.9-0.2_amd64.deb
pool/main/t/tmux/tmux_3.3a-3_amd64.deb
pool/main/t/tree/tree_2.1.0-1_amd64.deb
pool/main/t/tzdata/tzdata_2023c-5_all.deb
pool/main/u/unzip/unzip_6.0-28_amd64.deb
pool/main/u/usbutils/usbutils_014-1_amd64.deb
pool/main/u/usrmerge/usr-is-merged_35_all.deb
pool/main/u/util-linux/bsdextrautils_2.38.1-5+b1_amd64.deb
pool/main/u/util-linux/bsdutils_2.38.1-5+b1_amd64.deb
pool/main/u/util-linux/fdisk_2.38.1-5+b1_amd64.deb
pool/main/u/util-linux/libblkid1_2.38.1-5+b1_amd64.deb
pool/main/u/util-linux/libfdisk1_2.38.1-5+b1_amd64.deb
pool/main/u/util-linux/libmount1_2.38.1-5+b1_amd64.deb
pool/main/u/util-linux/libsmartcols1_2.38.1-5+b1_amd64.deb
pool/main/u/util-linux/libuuid1_2.38.1-5+b1_amd64.deb
pool/main/u/util-linux/mount_2.38.1-5+b1_amd64.deb
pool/main/u/util-linux/util-linux-extra_2.38.1-5+b1_amd64.deb
pool/main/u/util-linux/util-linux_2.38.1-5+b1_amd64.deb
pool/main/v/vim/vim-common_9.0.1378-2_all.deb
pool/main/v/vim/vim-runtime_9.0.1378-2_all.deb
pool/main/v/vim/vim-tiny_9.0.1378-2_amd64.deb
pool/main/v/vim/vim_9.0.1378-2_amd64.deb
pool/main/v/vim/xxd_9.0.1378-2_amd64.deb
pool/main/w/wget/wget_1.21.3-1+b2_amd64.deb
pool/main/x/xxhash/libxxhash0_0.8.1-1_amd64.deb
pool/main/x/xz-utils/liblzma5_5.4.1-0.2_amd64.deb
pool/main/x/xz-utils/xz-utils_5.4.1-0.2_amd64.deb
pool/main/z/z3/libz3-4_4.8.12-3.1_amd64.deb
pool/main/z/zlib/zlib1g_1.2.13.dfsg-1_amd64.deb
END

# Get the debian-security packages.
while read -r p; do
    if [ -n "${SNAPSHOT_SERVER_ONLY:-}" ]; then
        false
    else
        fetch debian-security "$DEBIAN_SECURITY_ROLLING" "$p"
    fi || fetch debian-security "$DEBIAN_SECURITY_SNAPSHOT" "$p"
done <<'END'
pool/updates/main/c/curl/libcurl3-gnutls_7.88.1-10+deb12u1_amd64.deb
pool/updates/main/l/linux-signed-amd64/linux-headers-amd64_6.1.52-1_amd64.deb
pool/updates/main/l/linux-signed-amd64/linux-image-6.1.0-12-amd64_6.1.52-1_amd64.deb
pool/updates/main/l/linux-signed-amd64/linux-image-amd64_6.1.52-1_amd64.deb
pool/updates/main/l/linux/linux-compiler-gcc-12-x86_6.1.52-1_amd64.deb
pool/updates/main/l/linux/linux-headers-6.1.0-12-amd64_6.1.52-1_amd64.deb
pool/updates/main/l/linux/linux-headers-6.1.0-12-common_6.1.52-1_all.deb
pool/updates/main/l/linux/linux-kbuild-6.1_6.1.52-1_amd64.deb
pool/updates/main/l/linux/linux-libc-dev_6.1.52-1_amd64.deb
END
