#!/bin/bash
# pris-rebuild-a.sh - Automated LFS build script, to be run on QEMU startup 
# (by root)

source "/pris/pris-fns.sh"

stty cols 92

if ! marker_exists "init" ; then
    cmd 'export LFS=/mnt/lfs'
    cmd 'umask 022'
    cmd 'mkdir -pv $LFS'
    cmd 'chown root:root $LFS'
    cmd 'chmod 755 $LFS'
    # TODO: check if this should be done here, or if it's already done earlier
    # cmd '/sbin/swapon -v /dev/<zzz>'
    cmd 'mkdir -v $LFS/sources'
    cmd 'chmod a+wt $LFS/sources'
    place_marker "init"
fi

export LFS=/mnt/lfs
umask 022

# TODO: set this when $LFS will be on a different partition
# cmd 'mount -v -t ext4 /dev/<xxx> $LFS'

if ! marker_exists "download-setup" ; then
    cmd 'wget --timeout=30 --tries=3 \
    -O /pris/wget-list-sysv \
    https://www.linuxfromscratch.org/lfs/downloads/stable/wget-list-sysv \
    || exit 1'
    cmd 'wget --timeout=30 --tries=3 \
    -O /pris/md5sums \
    https://www.linuxfromscratch.org/lfs/downloads/stable/md5sums \
    || exit 1'
    place_marker "download-setup"
fi

cmd 'MIRRORS=$(cat /pris/lfs-mirrors)'

if ! marker_exists "dl-acl" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /acl-2.3.2.tar.xz$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/acl-2.3.2.tar.xz ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources ${m%/}/acl-2.3.2.tar.xz \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " acl-2.3.2.tar.xz$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-acl"
fi

if ! marker_exists "dl-attr" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /attr-2.5.2.tar.gz$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/attr-2.5.2.tar.gz ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources ${m%/}/attr-2.5.2.tar.gz \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " attr-2.5.2.tar.gz$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-attr"
fi

if ! marker_exists "dl-autoconf" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /autoconf-2.72.tar.xz$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/autoconf-2.72.tar.xz ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources ${m%/}/autoconf-2.72.tar.xz \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " autoconf-2.72.tar.xz$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-autoconf"
fi

if ! marker_exists "dl-automake" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /automake-1.18.1.tar.xz$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/automake-1.18.1.tar.xz ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources ${m%/}/automake-1.18.1.tar.xz \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " automake-1.18.1.tar.xz$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-automake"
fi

if ! marker_exists "dl-bash" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /bash-5.3.tar.gz$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/bash-5.3.tar.gz ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources ${m%/}/bash-5.3.tar.gz \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " bash-5.3.tar.gz$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-bash"
fi

if ! marker_exists "dl-bc" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /bc-7.0.3.tar.xz$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/bc-7.0.3.tar.xz ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources ${m%/}/bc-7.0.3.tar.xz \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " bc-7.0.3.tar.xz$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-bc"
fi

if ! marker_exists "dl-binutils" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /binutils-2.45.tar.xz$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/binutils-2.45.tar.xz ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources ${m%/}/binutils-2.45.tar.xz \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " binutils-2.45.tar.xz$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-binutils"
fi

if ! marker_exists "dl-bison" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /bison-3.8.2.tar.xz$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/bison-3.8.2.tar.xz ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources ${m%/}/bison-3.8.2.tar.xz \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " bison-3.8.2.tar.xz$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-bison"
fi

if ! marker_exists "dl-bzip2" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /bzip2-1.0.8.tar.gz$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/bzip2-1.0.8.tar.gz ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources ${m%/}/bzip2-1.0.8.tar.gz \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " bzip2-1.0.8.tar.gz$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-bzip2"
fi

if ! marker_exists "dl-coreutils" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /coreutils-9.7.tar.xz$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/coreutils-9.7.tar.xz ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources ${m%/}/coreutils-9.7.tar.xz \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " coreutils-9.7.tar.xz$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-coreutils"
fi

if ! marker_exists "dl-dbus" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /dbus-1.16.2.tar.xz$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/dbus-1.16.2.tar.xz ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources ${m%/}/dbus-1.16.2.tar.xz \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " dbus-1.16.2.tar.xz$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-dbus"
fi

if ! marker_exists "dl-dejagnu" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /dejagnu-1.6.3.tar.gz$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/dejagnu-1.6.3.tar.gz ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources ${m%/}/dejagnu-1.6.3.tar.gz \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " dejagnu-1.6.3.tar.gz$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-dejagnu"
fi

if ! marker_exists "dl-diffutils" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /diffutils-3.12.tar.xz$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/diffutils-3.12.tar.xz ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources ${m%/}/diffutils-3.12.tar.xz \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " diffutils-3.12.tar.xz$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-diffutils"
fi

if ! marker_exists "dl-e2fsprogs" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /e2fsprogs-1.47.3.tar.gz$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/e2fsprogs-1.47.3.tar.gz ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources ${m%/}/e2fsprogs-1.47.3.tar.gz \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " e2fsprogs-1.47.3.tar.gz$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-e2fsprogs"
fi

if ! marker_exists "dl-elfutils" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /elfutils-0.193.tar.bz2$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/elfutils-0.193.tar.bz2 ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources ${m%/}/elfutils-0.193.tar.bz2 \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " elfutils-0.193.tar.bz2$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-elfutils"
fi

if ! marker_exists "dl-expat" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /expat-2.7.1.tar.xz$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/expat-2.7.1.tar.xz ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources ${m%/}/expat-2.7.1.tar.xz \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " expat-2.7.1.tar.xz$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-expat"
fi

if ! marker_exists "dl-expect" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /expect5.45.4.tar.gz$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/expect5.45.4.tar.gz ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources ${m%/}/expect5.45.4.tar.gz \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " expect5.45.4.tar.gz$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-expect"
fi

if ! marker_exists "dl-file" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /file-5.46.tar.gz$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/file-5.46.tar.gz ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources ${m%/}/file-5.46.tar.gz \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " file-5.46.tar.gz$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-file"
fi

if ! marker_exists "dl-findutils" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /findutils-4.10.0.tar.xz$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/findutils-4.10.0.tar.xz ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources ${m%/}/findutils-4.10.0.tar.xz \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " findutils-4.10.0.tar.xz$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-findutils"
fi

if ! marker_exists "dl-flex" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /flex-2.6.4.tar.gz$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/flex-2.6.4.tar.gz ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources ${m%/}/flex-2.6.4.tar.gz \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " flex-2.6.4.tar.gz$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-flex"
fi

if ! marker_exists "dl-flit-core" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /flit_core-3.12.0.tar.gz$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/flit_core-3.12.0.tar.gz ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources ${m%/}/flit_core-3.12.0.tar.gz \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " flit_core-3.12.0.tar.gz$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-flit-core"
fi

if ! marker_exists "dl-gawk" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /gawk-5.3.2.tar.xz$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/gawk-5.3.2.tar.xz ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources ${m%/}/gawk-5.3.2.tar.xz \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " gawk-5.3.2.tar.xz$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-gawk"
fi

if ! marker_exists "dl-gcc" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /gcc-15.2.0.tar.xz$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/gcc-15.2.0.tar.xz ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources ${m%/}/gcc-15.2.0.tar.xz \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " gcc-15.2.0.tar.xz$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-gcc"
fi

if ! marker_exists "dl-gdbm" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /gdbm-1.26.tar.gz$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/gdbm-1.26.tar.gz ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources ${m%/}/gdbm-1.26.tar.gz \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " gdbm-1.26.tar.gz$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-gdbm"
fi

if ! marker_exists "dl-gettext" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /gettext-0.26.tar.xz$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/gettext-0.26.tar.xz ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources ${m%/}/gettext-0.26.tar.xz \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " gettext-0.26.tar.xz$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-gettext"
fi

if ! marker_exists "dl-glibc" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /glibc-2.42.tar.xz$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/glibc-2.42.tar.xz ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources ${m%/}/glibc-2.42.tar.xz \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " glibc-2.42.tar.xz$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-glibc"
fi

if ! marker_exists "dl-gmp" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /gmp-6.3.0.tar.xz$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/gmp-6.3.0.tar.xz ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources ${m%/}/gmp-6.3.0.tar.xz \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " gmp-6.3.0.tar.xz$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-gmp"
fi

if ! marker_exists "dl-gperf" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /gperf-3.3.tar.gz$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/gperf-3.3.tar.gz ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources ${m%/}/gperf-3.3.tar.gz \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " gperf-3.3.tar.gz$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-gperf"
fi

if ! marker_exists "dl-grep" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /grep-3.12.tar.xz$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/grep-3.12.tar.xz ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources ${m%/}/grep-3.12.tar.xz \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " grep-3.12.tar.xz$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-grep"
fi

if ! marker_exists "dl-groff" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /groff-1.23.0.tar.gz$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/groff-1.23.0.tar.gz ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources ${m%/}/groff-1.23.0.tar.gz \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " groff-1.23.0.tar.gz$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-groff"
fi

if ! marker_exists "dl-grub" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /grub-2.12.tar.xz$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/grub-2.12.tar.xz ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources ${m%/}/grub-2.12.tar.xz \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " grub-2.12.tar.xz$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-grub"
fi

if ! marker_exists "dl-gzip" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /gzip-1.14.tar.xz$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/gzip-1.14.tar.xz ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources ${m%/}/gzip-1.14.tar.xz \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " gzip-1.14.tar.xz$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-gzip"
fi

if ! marker_exists "dl-iana-etc" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /iana-etc-20250807.tar.gz$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/iana-etc-20250807.tar.gz ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources ${m%/}/iana-etc-20250807.tar.gz \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " iana-etc-20250807.tar.gz$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-iana-etc"
fi

if ! marker_exists "dl-inetutils" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /inetutils-2.6.tar.xz$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/inetutils-2.6.tar.xz ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources ${m%/}/inetutils-2.6.tar.xz \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " inetutils-2.6.tar.xz$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-inetutils"
fi

if ! marker_exists "dl-intltool" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /intltool-0.51.0.tar.gz$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/intltool-0.51.0.tar.gz ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources ${m%/}/intltool-0.51.0.tar.gz \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " intltool-0.51.0.tar.gz$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-intltool"
fi

if ! marker_exists "dl-iproute2" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /iproute2-6.16.0.tar.xz$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/iproute2-6.16.0.tar.xz ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources ${m%/}/iproute2-6.16.0.tar.xz \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " iproute2-6.16.0.tar.xz$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-iproute2"
fi

if ! marker_exists "dl-jinja2" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /jinja2-3.1.6.tar.gz$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/jinja2-3.1.6.tar.gz ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources ${m%/}/jinja2-3.1.6.tar.gz \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " jinja2-3.1.6.tar.gz$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-jinja2"
fi

if ! marker_exists "dl-kbd" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /kbd-2.8.0.tar.xz$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/kbd-2.8.0.tar.xz ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources ${m%/}/kbd-2.8.0.tar.xz \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " kbd-2.8.0.tar.xz$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-kbd"
fi

if ! marker_exists "dl-kmod" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /kmod-34.2.tar.xz$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/kmod-34.2.tar.xz ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources ${m%/}/kmod-34.2.tar.xz \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " kmod-34.2.tar.xz$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-kmod"
fi

if ! marker_exists "dl-less" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /less-679.tar.gz$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/less-679.tar.gz ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources ${m%/}/less-679.tar.gz \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " less-679.tar.gz$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-less"
fi

if ! marker_exists "dl-lfs-bootscripts" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /lfs-bootscripts-20250827.tar.xz$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/lfs-bootscripts-20250827.tar.xz ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources \
            ${m%/}/lfs-bootscripts-20250827.tar.xz \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " lfs-bootscripts-20250827.tar.xz$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-lfs-bootscripts"
fi

if ! marker_exists "dl-libcap" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /libcap-2.76.tar.xz$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/libcap-2.76.tar.xz ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources ${m%/}/libcap-2.76.tar.xz \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " libcap-2.76.tar.xz$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-libcap"
fi

if ! marker_exists "dl-libffi" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /libffi-3.5.2.tar.gz$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/libffi-3.5.2.tar.gz ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources ${m%/}/libffi-3.5.2.tar.gz \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " libffi-3.5.2.tar.gz$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-libffi"
fi

if ! marker_exists "dl-libpipeline" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /libpipeline-1.5.8.tar.gz$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/libpipeline-1.5.8.tar.gz ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources ${m%/}/libpipeline-1.5.8.tar.gz \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " libpipeline-1.5.8.tar.gz$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-libpipeline"
fi

if ! marker_exists "dl-libtool" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /libtool-2.5.4.tar.xz$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/libtool-2.5.4.tar.xz ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources ${m%/}/libtool-2.5.4.tar.xz \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " libtool-2.5.4.tar.xz$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-libtool"
fi

if ! marker_exists "dl-libxcrypt" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /libxcrypt-4.4.38.tar.xz$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/libxcrypt-4.4.38.tar.xz ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources ${m%/}/libxcrypt-4.4.38.tar.xz \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " libxcrypt-4.4.38.tar.xz$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-libxcrypt"
fi

if ! marker_exists "dl-linux" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /linux-6.16.1.tar.xz$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/linux-6.16.1.tar.xz ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources ${m%/}/linux-6.16.1.tar.xz \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " linux-6.16.1.tar.xz$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-linux"
fi

if ! marker_exists "dl-lz4" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /lz4-1.10.0.tar.gz$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/lz4-1.10.0.tar.gz ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources ${m%/}/lz4-1.10.0.tar.gz \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " lz4-1.10.0.tar.gz$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-lz4"
fi

if ! marker_exists "dl-m4" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /m4-1.4.20.tar.xz$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/m4-1.4.20.tar.xz ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources ${m%/}/m4-1.4.20.tar.xz \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " m4-1.4.20.tar.xz$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-m4"
fi

if ! marker_exists "dl-make" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /make-4.4.1.tar.gz$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/make-4.4.1.tar.gz ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources ${m%/}/make-4.4.1.tar.gz \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " make-4.4.1.tar.gz$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-make"
fi

if ! marker_exists "dl-man-db" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /man-db-2.13.1.tar.xz$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/man-db-2.13.1.tar.xz ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources ${m%/}/man-db-2.13.1.tar.xz \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " man-db-2.13.1.tar.xz$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-man-db"
fi

if ! marker_exists "dl-man-pages" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /man-pages-6.15.tar.xz$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/man-pages-6.15.tar.xz ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources ${m%/}/man-pages-6.15.tar.xz \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " man-pages-6.15.tar.xz$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-man-pages"
fi

if ! marker_exists "dl-markupsafe" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /markupsafe-3.0.2.tar.gz$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/markupsafe-3.0.2.tar.gz ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources ${m%/}/markupsafe-3.0.2.tar.gz \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " markupsafe-3.0.2.tar.gz$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-markupsafe"
fi

if ! marker_exists "dl-meson" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /meson-1.8.3.tar.gz$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/meson-1.8.3.tar.gz ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources ${m%/}/meson-1.8.3.tar.gz \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " meson-1.8.3.tar.gz$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-meson"
fi

if ! marker_exists "dl-mpc" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /mpc-1.3.1.tar.gz$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/mpc-1.3.1.tar.gz ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources ${m%/}/mpc-1.3.1.tar.gz \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " mpc-1.3.1.tar.gz$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-mpc"
fi

if ! marker_exists "dl-mpfr" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /mpfr-4.2.2.tar.xz$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/mpfr-4.2.2.tar.xz ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources ${m%/}/mpfr-4.2.2.tar.xz \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " mpfr-4.2.2.tar.xz$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-mpfr"
fi

if ! marker_exists "dl-ncurses" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /ncurses-6.5-20250809.tgz$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/ncurses-6.5-20250809.tgz ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources ${m%/}/ncurses-6.5-20250809.tgz \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " ncurses-6.5-20250809.tgz$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-ncurses"
fi

if ! marker_exists "dl-ninja" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /ninja-1.13.1.tar.gz$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/ninja-1.13.1.tar.gz ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources ${m%/}/ninja-1.13.1.tar.gz \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " ninja-1.13.1.tar.gz$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-ninja"
fi

if ! marker_exists "dl-openssl" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /openssl-3.5.2.tar.gz$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/openssl-3.5.2.tar.gz ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources ${m%/}/openssl-3.5.2.tar.gz \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " openssl-3.5.2.tar.gz$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-openssl"
fi

if ! marker_exists "dl-packaging" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /packaging-25.0.tar.gz$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/packaging-25.0.tar.gz ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources ${m%/}/packaging-25.0.tar.gz \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " packaging-25.0.tar.gz$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-packaging"
fi

if ! marker_exists "dl-patch" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /patch-2.8.tar.xz$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/patch-2.8.tar.xz ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources ${m%/}/patch-2.8.tar.xz \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " patch-2.8.tar.xz$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-patch"
fi

if ! marker_exists "dl-perl" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /perl-5.42.0.tar.xz$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/perl-5.42.0.tar.xz ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources ${m%/}/perl-5.42.0.tar.xz \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " perl-5.42.0.tar.xz$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-perl"
fi

if ! marker_exists "dl-pkgconf" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /pkgconf-2.5.1.tar.xz$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/pkgconf-2.5.1.tar.xz ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources ${m%/}/pkgconf-2.5.1.tar.xz \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " pkgconf-2.5.1.tar.xz$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-pkgconf"
fi

if ! marker_exists "dl-procps-ng" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /procps-ng-4.0.5.tar.xz$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/procps-ng-4.0.5.tar.xz ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources ${m%/}/procps-ng-4.0.5.tar.xz \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " procps-ng-4.0.5.tar.xz$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-procps-ng"
fi

if ! marker_exists "dl-psmisc" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /psmisc-23.7.tar.xz$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/psmisc-23.7.tar.xz ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources ${m%/}/psmisc-23.7.tar.xz \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " psmisc-23.7.tar.xz$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-psmisc"
fi

if ! marker_exists "dl-python" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /Python-3.13.7.tar.xz$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/Python-3.13.7.tar.xz ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources ${m%/}/Python-3.13.7.tar.xz \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " Python-3.13.7.tar.xz$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-python"
fi

if ! marker_exists "dl-python-docs" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /python-3.13.7-docs-html.tar.bz2$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/python-3.13.7-docs-html.tar.bz2 ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources \
            ${m%/}/python-3.13.7-docs-html.tar.bz2 \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " python-3.13.7-docs-html.tar.bz2$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-python-docs"
fi

if ! marker_exists "dl-readline" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /readline-8.3.tar.gz$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/readline-8.3.tar.gz ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources ${m%/}/readline-8.3.tar.gz \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " readline-8.3.tar.gz$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-readline"
fi

if ! marker_exists "dl-sed" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /sed-4.9.tar.xz$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/sed-4.9.tar.xz ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources ${m%/}/sed-4.9.tar.xz \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " sed-4.9.tar.xz$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-sed"
fi

if ! marker_exists "dl-setuptools" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /setuptools-80.9.0.tar.gz$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/setuptools-80.9.0.tar.gz ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources ${m%/}/setuptools-80.9.0.tar.gz \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " setuptools-80.9.0.tar.gz$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-setuptools"
fi

if ! marker_exists "dl-shadow" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /shadow-4.18.0.tar.xz$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/shadow-4.18.0.tar.xz ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources ${m%/}/shadow-4.18.0.tar.xz \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " shadow-4.18.0.tar.xz$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-shadow"
fi

if ! marker_exists "dl-sysklogd" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /sysklogd-2.7.2.tar.gz$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/sysklogd-2.7.2.tar.gz ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources ${m%/}/sysklogd-2.7.2.tar.gz \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " sysklogd-2.7.2.tar.gz$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-sysklogd"
fi

if ! marker_exists "dl-systemd" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /systemd-257.8.tar.gz$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/systemd-257.8.tar.gz ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources ${m%/}/systemd-257.8.tar.gz \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " systemd-257.8.tar.gz$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-systemd"
fi

if ! marker_exists "dl-systemd-man-pages" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /systemd-man-pages-257.8.tar.xz$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/systemd-man-pages-257.8.tar.xz ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources \
            ${m%/}/systemd-man-pages-257.8.tar.xz \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " systemd-man-pages-257.8.tar.xz$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-systemd-man-pages"
fi

if ! marker_exists "dl-sysvinit" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /sysvinit-3.14.tar.xz$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/sysvinit-3.14.tar.xz ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources ${m%/}/sysvinit-3.14.tar.xz \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " sysvinit-3.14.tar.xz$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-sysvinit"
fi

if ! marker_exists "dl-tar" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /tar-1.35.tar.xz$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/tar-1.35.tar.xz ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources ${m%/}/tar-1.35.tar.xz \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " tar-1.35.tar.xz$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-tar"
fi

if ! marker_exists "dl-tcl" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /tcl8.6.16-src.tar.gz$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/tcl8.6.16-src.tar.gz ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources ${m%/}/tcl8.6.16-src.tar.gz \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " tcl8.6.16-src.tar.gz$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-tcl"
fi

if ! marker_exists "dl-tcl-html" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /tcl8.6.16-html.tar.gz$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/tcl8.6.16-html.tar.gz ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources ${m%/}/tcl8.6.16-html.tar.gz \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " tcl8.6.16-html.tar.gz$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-tcl-html"
fi

if ! marker_exists "dl-texinfo" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /texinfo-7.2.tar.xz$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/texinfo-7.2.tar.xz ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources ${m%/}/texinfo-7.2.tar.xz \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " texinfo-7.2.tar.xz$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-texinfo"
fi

if ! marker_exists "dl-tzdata" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /tzdata2025b.tar.gz$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/tzdata2025b.tar.gz ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources ${m%/}/tzdata2025b.tar.gz \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " tzdata2025b.tar.gz$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-tzdata"
fi

if ! marker_exists "dl-udev-lfs" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /udev-lfs-20230818.tar.xz$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/udev-lfs-20230818.tar.xz ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources ${m%/}/udev-lfs-20230818.tar.xz \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " udev-lfs-20230818.tar.xz$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-udev-lfs"
fi

if ! marker_exists "dl-util-linux" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /util-linux-2.41.1.tar.xz$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/util-linux-2.41.1.tar.xz ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources ${m%/}/util-linux-2.41.1.tar.xz \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " util-linux-2.41.1.tar.xz$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-util-linux"
fi

if ! marker_exists "dl-vim" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /vim-9.1.1629.tar.gz$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/vim-9.1.1629.tar.gz ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources ${m%/}/vim-9.1.1629.tar.gz \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " vim-9.1.1629.tar.gz$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-vim"
fi

if ! marker_exists "dl-wheel" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /wheel-0.46.1.tar.gz$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/wheel-0.46.1.tar.gz ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources ${m%/}/wheel-0.46.1.tar.gz \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " wheel-0.46.1.tar.gz$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-wheel"
fi

if ! marker_exists "dl-xml-parser" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /XML-Parser-2.47.tar.gz$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/XML-Parser-2.47.tar.gz ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources ${m%/}/XML-Parser-2.47.tar.gz \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " XML-Parser-2.47.tar.gz$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-xml-parser"
fi

if ! marker_exists "dl-xz" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /xz-5.8.1.tar.xz$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/xz-5.8.1.tar.xz ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources ${m%/}/xz-5.8.1.tar.xz \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " xz-5.8.1.tar.xz$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-xz"
fi

if ! marker_exists "dl-zlib" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /zlib-1.3.1.tar.gz$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/zlib-1.3.1.tar.gz ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources ${m%/}/zlib-1.3.1.tar.gz \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " zlib-1.3.1.tar.gz$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-zlib"
fi

if ! marker_exists "dl-zstd" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /zstd-1.5.7.tar.gz$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/zstd-1.5.7.tar.gz ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources ${m%/}/zstd-1.5.7.tar.gz \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " zstd-1.5.7.tar.gz$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-zstd"
fi

if ! marker_exists "dl-bzip2-patch" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /bzip2-1.0.8-install_docs-1.patch$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/bzip2-1.0.8-install_docs-1.patch ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources \
            ${m%/}/bzip2-1.0.8-install_docs-1.patch \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " bzip2-1.0.8-install_docs-1.patch$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-bzip2-patch"
fi

if ! marker_exists "dl-coreutils-upstream-fix" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /coreutils-9.7-upstream_fix-1.patch$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/coreutils-9.7-upstream_fix-1.patch ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources \
            ${m%/}/coreutils-9.7-upstream_fix-1.patch \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " coreutils-9.7-upstream_fix-1.patch$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-coreutils-upstream-fix"
fi

if ! marker_exists "dl-coreutils-i18n" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /coreutils-9.7-i18n-1.patch$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/coreutils-9.7-i18n-1.patch ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources \
            ${m%/}/coreutils-9.7-i18n-1.patch \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " coreutils-9.7-i18n-1.patch$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-coreutils-i18n"
fi

if ! marker_exists "dl-expect-patch" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /expect-5.45.4-gcc15-1.patch$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/expect-5.45.4-gcc15-1.patch ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources \
            ${m%/}/expect-5.45.4-gcc15-1.patch \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " expect-5.45.4-gcc15-1.patch$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-expect-patch"
fi

if ! marker_exists "dl-glibc-fhs" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /glibc-2.42-fhs-1.patch$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/glibc-2.42-fhs-1.patch ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources \
            ${m%/}/glibc-2.42-fhs-1.patch \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " glibc-2.42-fhs-1.patch$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-glibc-fhs"
fi

if ! marker_exists "dl-kbd-backspace" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /kbd-2.8.0-backspace-1.patch$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/kbd-2.8.0-backspace-1.patch ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources \
            ${m%/}/kbd-2.8.0-backspace-1.patch \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " kbd-2.8.0-backspace-1.patch$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-kbd-backspace"
fi

if ! marker_exists "dl-sysvinit-patch" ; then
    cmd 'wget --timeout=30 --tries=2 -c --progress=bar \
    -P $LFS/sources \
    $(grep /sysvinit-3.14-consolidated-1.patch$ /pris/wget-list-sysv)'
    cmd '[ -f $LFS/sources/sysvinit-3.14-consolidated-1.patch ] || \
    for m in $MIRRORS; do \
        wget --timeout=30 --tries=1 -c --progress=bar \
            -P $LFS/sources \
            ${m%/}/sysvinit-3.14-consolidated-1.patch \
            && break; \
    done'
    cmd '(cd $LFS/sources \
    && grep " sysvinit-3.14-consolidated-1.patch$" /pris/md5sums \
    | md5sum -c)' \
    && place_marker "dl-sysvinit-patch"
fi

if ! marker_exists "lfs-filesystem" ; then
    cmd 'mkdir -pv $LFS/{etc,var} $LFS/usr/{bin,lib,sbin}'
    cmd 'for i in bin lib sbin; do
  ln -sv usr/$i $LFS/$i
done'
    cmd 'case $(uname -m) in
  x86_64) mkdir -pv $LFS/lib64 ;;
esac'
    cmd 'mkdir -pv $LFS/tools'
    place_marker "lfs-filesystem"
fi

if ! marker_exists "lfs-user-a" ; then
    cmd '[ ! -e /etc/bash.bashrc ] || mv -v /etc/bash.bashrc /etc/bash.bashrc.NOUSE'
    cmd 'groupadd lfs'
    cmd 'useradd -s /bin/bash -g lfs -m -k /dev/null lfs'
    cmd 'chown -v lfs $LFS/{usr{,/*},var,etc,tools}'
    cmd 'case $(uname -m) in
  x86_64) chown -v lfs $LFS/lib64 ;;
esac'

    # Make sure lfs env is virginal.
    if test -f "${LFS_HOME}/.bash_profile" ; then
        rm "${LFS_HOME}/.bash_profile"
    fi
    if test -f "${LFS_HOME}/.bashrc" ; then
        rm "${LFS_HOME}/.bashrc"
    fi

    # Will substitute the following with part b of the rebuild script run as lfs user.
    echo_cmd 'su - lfs'
    place_marker "lfs-user-a"
fi

# Run the next part of build as lfs user
su - lfs -c "bash ${PRIS_DIR}/pris-rebuild-b.sh"

if ! marker_exists "virtual-kernel-fs" ; then
    cmd 'chown --from lfs -R root:root $LFS/{usr,var,etc,tools}'
    cmd 'case $(uname -m) in
  x86_64) chown --from lfs -R root:root $LFS/lib64 ;;
esac'
    cmd 'mkdir -pv $LFS/{dev,proc,sys,run}'

    mkdir -p "$LFS/pris"

    place_marker "virtual-kernel-fs"
fi

cmd 'mount -v --bind /dev $LFS/dev'
cmd 'mount -vt devpts devpts -o gid=5,mode=0620 $LFS/dev/pts'
cmd 'mount -vt proc proc $LFS/proc'
cmd 'mount -vt sysfs sysfs $LFS/sys'
cmd 'mount -vt tmpfs tmpfs $LFS/run'
cmd 'if [ -h $LFS/dev/shm ]; then
  install -v -d -m 1777 $LFS$(realpath /dev/shm)
else
  mount -vt tmpfs -o nosuid,nodev tmpfs $LFS/dev/shm
fi'

# Mount pris to be available after chroot.
mkdir -p "$LFS/pris"
mount --bind ${PRIS_DIR} "$LFS/pris"
# mount "/dev/hdb3" "$LFS/pris"

# In chroot env, run pris-rebuild-c.sh.
echo_cmd "chroot \"\$LFS\" /usr/bin/env -i \\
    HOME=/root \\
    TERM=\"\$TERM\" \\
    PS1='(lfs chroot) [\h:\w]\\\\n\\\033\[31m>\\\033\[0m ' \\
    PATH=/usr/bin:/usr/sbin \\
    MAKEFLAGS=\"-j\$(nproc)\" \\
    TESTSUITEFLAGS=\"-j\$(nproc)\" \\
    /bin/bash --login"
chroot "$LFS" /usr/bin/env -i   \
    HOME=/root                  \
    TERM="$TERM"                \
    PS1='(lfs chroot) [\h:\w]\n\033[31m>\033[0m ' \
    PATH=/usr/bin:/usr/sbin     \
    MAKEFLAGS="-j$(nproc)"      \
    TESTSUITEFLAGS="-j$(nproc)" \
    /bin/bash --login "${PRIS_DIR}/pris-rebuild-c.sh"

# Build complete.
# For the following command, need to run a slightly different version to send complete lines,
# in order to be flushed to the log.
echo_cmd "COLS=\$(tput cols)
printf '%*s\\n' \"\$COLS\" '' | tr ' ' '='
END=\$(( \$(date +%s) + 86400 ))
while [ \$(date +%s) -lt \$END ]; do
    R=\$(( END - \$(date +%s) ))
    printf '\r%-20s%*sReboot in %02d:%02d' \\
        'COMPILATION COMPLETE' \$(( COLS - 35 )) '' \\
            \$(( R/3600 )) \$(( (R%3600)/60 ))
    sleep 60
done
unset R END COLS
echo"

COLS=$(tput cols)
printf '%*s\n' "$COLS" '' | tr ' ' '='
END=$(( $(date +%s) + 86400 ))
while [ $(date +%s) -lt $END ]; do
    R=$(( END - $(date +%s) ))
    printf '%-20s%*sReboot in %02d:%02d\n' \
        'COMPILATION COMPLETE' $(( COLS - 35 )) '' \
            $(( R/3600 )) $(( (R%3600)/60 ))
    sleep 60
done
unset R END COLS
