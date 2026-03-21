#!/bin/bash
# pris-rebuild-a.sh - Automated LFS build script, to be run on QEMU startup 
# (by root)

source "/pris/pris-fns.sh"

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

if ! marker_exists "download-packages" ; then
    # TODO: replace this script with inline download shell command
    echo_cmd 'cat > /pris/download-packages.sh << DOWNLOAD_SCRIPT
#!/bin/bash

WGET_LIST="$1"
MIRROR_LIST="$2"
MD5SUMS="$3"
DEST="${LFS}/sources"
FAILURES_LOG="$DEST/download-failures.log"

for f in "$WGET_LIST" "$MIRROR_LIST" "$MD5SUMS"; do
    if [ ! -f "$f" ]; then
        echo "ERROR: missing input file: $f"
        exit 1
    fi
    if [ ! -s "$f" ]; then
        echo "ERROR: empty input file: $f"
        exit 1
    fi
done

mkdir -p "$DEST"
> "$FAILURES_LOG"

download_file() {
    local url="$1"
    local filename="$2"

    if wget --timeout=30 --tries=2 --continue \
            --progress=bar --directory-prefix="$DEST" "$url"; then
        return 0
    fi

    echo "Primary failed for $filename, trying mirrors..."
    while IFS= read -r mirror; do
        [ -z "$mirror" ] && continue
        mirror_url="${mirror%/}/$filename"
        echo "  Trying: $mirror_url"
        if wget --timeout=30 --tries=1 --continue \
                --progress=bar --directory-prefix="$DEST" "$mirror_url"; then
            return 0
        fi
    done < "$MIRROR_LIST"

    return 1
}

check_md5() {
    local filename="$1"
    local expected_md5

    expected_md5=$(grep " $filename$" "$MD5SUMS" | awk '{print $1}')
    if [ -z "$expected_md5" ]; then
        echo "  WARNING: No md5sum entry found for $filename, skipping check"
        return 0
    fi

    actual_md5=$(md5sum "$DEST/$filename" | awk '{print $1}')
    if [ "$actual_md5" != "$expected_md5" ]; then
        echo "  MD5 MISMATCH for $filename"
        echo "    expected: $expected_md5"
        echo "    actual:   $actual_md5"
        rm -f "$DEST/$filename"
        return 1
    fi

    echo "  MD5 OK: $filename"
    return 0
}

while IFS= read -r url; do
    [ -z "$url" ] && continue
    filename=$(basename "$url")

    if [ -f "$DEST/$filename" ]; then
        echo "Already have $filename, verifying md5..."
        if check_md5 "$filename"; then
            continue
        fi
        echo "  Re-downloading $filename due to md5 failure..."
    fi

    echo "Downloading $filename..."
    if ! download_file "$url" "$filename"; then
        echo "FAILED to download: $filename" | tee -a "$FAILURES_LOG"
        continue
    fi

    if ! check_md5 "$filename"; then
        echo "FAILED md5 check: $filename" | tee -a "$FAILURES_LOG"
        exit 1
    fi

done < "$WGET_LIST"

echo "---"
if [ -s "$FAILURES_LOG" ]; then
    echo "Some downloads failed. See $FAILURES_LOG"
    exit 1
else
    echo "All packages downloaded and verified successfully."
fi
DOWNLOAD_SCRIPT'

    cmd 'chmod +x /pris/download-packages.sh'
    cmd 'wget --timeout=30 --tries=3 \
    -O /pris/wget-list-sysv \
    https://www.linuxfromscratch.org/lfs/downloads/stable/wget-list-sysv \
    || exit 1'
    cmd 'wget --timeout=30 --tries=3 \
    -O /pris/md5sums \
    https://www.linuxfromscratch.org/lfs/downloads/stable/md5sums \
    || exit 1'
    cmd '/pris/download-packages.sh /pris/wget-list-sysv /pris/lfs-mirrors /pris/md5sums \
    || exit 1'
    place_marker "download-packages"
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

if ! marker_exists "virtual-kernel-filesystem" ; then
    cmd 'chown --from lfs -R root:root $LFS/{usr,var,etc,tools}'
    cmd 'case $(uname -m) in
  x86_64) chown --from lfs -R root:root $LFS/lib64 ;;
esac'
    cmd 'mkdir -pv $LFS/{dev,proc,sys,run}'

    mkdir -p "$LFS/pris"

    place_marker "virtual-kernel-filesystem"
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
