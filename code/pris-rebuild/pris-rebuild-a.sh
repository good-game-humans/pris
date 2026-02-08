#!/bin/bash

source "/pris/pris-fns.sh"
source "/pris/pris-pkgs.sh"

##############################################################################
## INIT                                                                     ##

write_pid "pris-rebuild-a"
mkdir -p ${PRIS_MARKER_DIR}
chown root:pris ${PRIS_MARKER_DIR}
chmod 775 ${PRIS_MARKER_DIR}
incr_restart_cnt
open_sgnl_io && echo unrest >&${SGNL_IO}
open_sgnl_io && echo unreboot >&${SGNL_IO}

##############################################################################
## MAIN                                                                     ##

if ! marker_exists "mkreiserfs" ; then
    if test -f ${PRIS_LOG} ; then
        rm ${PRIS_LOG}
    fi
    cmd "mkreiserfs -q /dev/hdb2"
    echo_cmd "mkswap /dev/hdb1"
    place_marker "mkreiserfs"
fi

if marker_exists "mkreiserfs" ; then

    cmd "export LFS=${MOUNT}"
    cmd "mkdir -pv ${MOUNT}"
    cmd "mount -v -t reiserfs /dev/hdb2 ${MOUNT}"
    #cmd "/sbin/swapon -v /dev/hdb1"

    if ! marker_exists "tools-env" ; then
        cmd "mkdir -v ${MOUNT}/src"
        cmd "chmod -v a+wt ${MOUNT}/src"
        cmd "mkdir -v ${MOUNT}/tools"
        test -h /tools && rm /tools
        cmd "ln -sv ${MOUNT}/tools /"
        echo_cmd "groupadd pris"
        echo_cmd "useradd -s /bin/bash -g pris -m -k /dev/null lfs"
        # Omitted passwd for lfs
        cmd "chown -v lfs ${MOUNT}/tools"
        cmd "chown -v lfs ${MOUNT}/src"
        place_marker "tools-env"
    fi

    # Make sure lfs user can write to log.
    touch ${PRIS_LOG}
    chgrp pris ${PRIS_LOG}
    chmod g+w ${PRIS_LOG}

    # Head fake; pass to rebuild-b
    if ! marker_exists "tools" ; then
        # Make sure lfs env is virginal.
        if test -f "${LFS_HOME}/.bash_profile" ; then
            rm "${LFS_HOME}/.bash_profile"
        fi
        if test -f "${LFS_HOME}/.bashrc" ; then
            rm "${LFS_HOME}/.bashrc"
        fi
        echo_cmd "su - lfs"
        su -c "sh ${PRIS_DIR}/pris-rebuild-b.sh" - lfs

        # Back from rebuild-b
        cmd "chown -R root:root ${MOUNT}/tools"
        place_marker "tools"
    fi

    if ! marker_exists "dev-nodes" ; then
        cmd "mkdir -pv ${MOUNT}/{dev,proc,sys}"
        cmd "mknod -m 600 ${MOUNT}/dev/console c 5 1"
        cmd "mknod -m 666 ${MOUNT}/dev/null c 1 3"
        place_marker "dev-nodes"
    fi

    # Virtual kernel fs mount points must always be done 
    # Should check if already mounted?
    cmd "mount -v --bind /dev ${MOUNT}/dev"
    cmd "mount -vt devpts devpts ${MOUNT}/dev/pts"
    cmd "mount -vt tmpfs shm ${MOUNT}/dev/shm"
    cmd "mount -vt proc proc ${MOUNT}/proc"
    cmd "mount -vt sysfs sysfs ${MOUNT}/sys"

    # Mount pris to be available after chroot.
    mkdir -p "${MOUNT}/pris"
    mount "/dev/hdb3" "${MOUNT}/pris"

    # Pre-download pkgs before chroot since wget won't be available.
    cmd "cd ${MOUNT}/src"
    if ! marker_exists "preget-pkgs" ; then
        download_pkg ${AUTOCONF_PKG}
        download_pkg ${AUTOMAKE_PKG}
        download_pkg ${BERKELEY_DB_PKG}
        download_pkg ${BISON_PKG}
        download_pkg ${FILE_PKG}
        download_pkg ${FLEX_PKG}
        download_pkg ${GROFF_PKG}
        download_pkg ${GRUB_PKG}
        download_pkg ${IANA_ETC_PKG}
        download_pkg ${INETUTILS_PKG}
        download_pkg ${IPROUTE2_PKG}
        download_pkg ${KBD_PKG}
        download_pkg ${LESS_PKG}
        download_pkg ${LFS_BOOTSCRIPTS_PKG}
        download_pkg ${LIBTOOL_PKG}
        download_pkg ${MAN_DB_PKG}
        download_pkg ${MAN_PAGES_PKG}
        download_pkg ${MODULE_INIT_TOOLS_PKG}
        download_pkg ${PROCPS_PKG}
        download_pkg ${PSMISC_PKG}
        download_pkg ${READLINE_PKG}
        download_pkg ${SHADOW_PKG}
        download_pkg ${SYSKLOGD_PKG}
        download_pkg ${SYSVINIT_PKG}
        download_pkg ${UDEV_PKG}
        download_pkg ${UDEV_CONFIG_PKG}
        download_pkg ${ZLIB_PKG}
        download_pkg ${WGET_PKG}
        download_pkg ${JOE_PKG}
        download_patches ${AUTOMAKE_PATCH0}
        download_patches ${BINUTILS_PATCH1}
        download_patches ${BZIP2_PATCH0}
        download_patches ${COREUTILS_PATCH0} ${COREUTILS_PATCH2}
        download_patches ${BERKELEY_DB_PATCH0}
        download_patches ${DIFFUTILS_PATCH0}
        download_patches ${GLIBC_PATCH0} ${GLIBC_PATCH1}
        download_patches ${GREP_PATCH0} ${GREP_PATCH1}
        download_patches ${GROFF_PATCH0}
        download_patches ${GRUB_PATCH0} ${GRUB_PATCH1}
        download_patches ${INETUTILS_PATCH0}
        download_patches ${KBD_PATCH0}
        download_patches ${MKTEMP_PATCH0}
        download_patches ${MODULE_INIT_TOOLS_PATCH0}
        download_patches ${NCURSES_PATCH0}
        download_patches ${PROCPS_PATCH0}
        download_patches ${READLINE_PATCH0}
        download_patches ${SHADOW_PATCH0}
        place_marker "preget-pkgs"
    fi

    # Chroot; another head-fake
    echo_cmd "chroot ${MOUNT} /tools/bin/env -i \\
    HOME=/root TERM=\"\$TERM\" PS1='[\h:\w]\\\\n> ' \\
    PATH=/bin:/usr/bin:/sbin:/usr/sbin:/tools/bin \\
    /tools/bin/bash --login +h"
    place_marker "TMP-ck-chroot-line-break"
    chroot "${MOUNT}" /tools/bin/env -i \
    HOME=/root TERM="$TERM" PS1='[\h:\w]\n> ' \
    PATH=/bin:/usr/bin:/sbin:/usr/sbin:/tools/bin \
    /tools/bin/bash --login +h "${PRIS_DIR}/pris-rebuild-c.sh"

    # Done.
    victory_dance
    
    # Send signal that we're resting.
    open_sgnl_io && echo rest >&${SGNL_IO}
    place_marker "resting"
    sleep 1d

    # Clear log and markers
    rm "${PRIS_LOG}"
    rm -Rf "${PRIS_MARKER_DIR}"
    rm "${RESTART_CNT}"

    # Unmount fs
    cmd "umount -v ${MOUNT}/dev/pts"
    cmd "umount -v ${MOUNT}/dev/shm"
    cmd "umount -v ${MOUNT}/dev"
    cmd "umount -v ${MOUNT}/proc"
    cmd "umount -v ${MOUNT}/sys"

    # Send signal we're rebooting.
    open_sgnl_io && echo reboot >&${SGNL_IO}
    open_sgnl_io && echo unrest >&${SGNL_IO}

    echo_cmd "umount -v ${MOUNT}/pris"
    umount "${MOUNT}/pris"
    echo_cmd "umount -v ${MOUNT}"
    umount "${MOUNT}"
    echo_cmd "shutdown -r now"
    killall pris-tail.sh
    shutdown -r now

fi

exit 0
