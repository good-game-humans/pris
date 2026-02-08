#!/bin/bash

source "/pris/pris-fns.sh"
source "/pris/pris-pkgs.sh"

##############################################################################
## INIT                                                                     ##

write_pid "pris-rebuild-d"

##############################################################################
## MAIN                                                                     ##

cmd "cd /src"

if ! marker_exists "bzip2" ; then
    unpack_pkg ${BZIP2_PKG}
    get_patch_files ${BZIP2_PATCH0}
    cmd "cd ${PKG_WORKDIR}"
    cmd "patch -Np1 -i ../${PATCH_FILES[0]}"
    cmd "make -f Makefile-libbz2_so"
    cmd "make clean"
    cmd "make"
    cmd "make PREFIX=/usr install"
    cmd "cp -v bzip2-shared /bin/bzip2"
    cmd "cp -av libbz2.so* /lib"
    cmd "ln -sv ../../lib/libbz2.so.1.0 /usr/lib/libbz2.so"
    cmd "rm -v /usr/bin/{bunzip2,bzcat,bzip2}"
    cmd "ln -sv bzip2 /bin/bunzip2"
    cmd "ln -sv bzip2 /bin/bzcat"
    cmd "cd .."
    cmd "rm -rf ${PKG_WORKDIR}"
    place_marker "bzip2"
fi

if ! marker_exists "diffutils" ; then
    unpack_pkg ${DIFFUTILS_PKG}
    get_patch_files ${DIFFUTILS_PATCH0}
    cmd "cd ${PKG_WORKDIR}"
    cmd "patch -Np1 -i ../${PATCH_FILES[0]}"
    cmd "touch man/diff.1"
    cmd "./configure --prefix=/usr"
    cmd "make"
    cmd "make install"
    cmd "cd .."
    cmd "rm -rf ${PKG_WORKDIR}"
    place_marker "diffutils"
fi

if ! marker_exists "file" ; then
    unpack_pkg ${FILE_PKG}
    cmd "cd ${PKG_WORKDIR}"
    cmd "sed -i -e '197,+1d' \\
       -e '189,+1d' \\
       -e 's/token\$/tokens/' doc/file.man"
    cmd "./configure --prefix=/usr"
    cmd "make"
    cmd "make install"
    cmd "cd .."
    cmd "rm -rf ${PKG_WORKDIR}"
    place_marker "file"
fi

if ! marker_exists "gawk" ; then
    unpack_pkg ${GAWK_PKG}
    cmd "cd ${PKG_WORKDIR}"
    cmd "./configure --prefix=/usr --libexecdir=/usr/lib \\
    ac_cv_func_working_mktime=yes"
    cmd "make"
    cmd "make install"
    cmd "cd .."
    cmd "rm -rf ${PKG_WORKDIR}"
    place_marker "gawk"
fi

if ! marker_exists "findutils" ; then
    unpack_pkg ${FINDUTILS_PKG}
    cmd "cd ${PKG_WORKDIR}"
    cmd "./configure --prefix=/usr --libexecdir=/usr/lib/findutils \\
    --localstatedir=/var/lib/locate"
    cmd "make"
    cmd "make install"
    cmd "mv -v /usr/bin/find /bin"
    cmd "sed -i -e 's/find:=\${BINDIR}/find:=\\/bin/' /usr/bin/updatedb"
    cmd "cd .."
    cmd "rm -rf ${PKG_WORKDIR}"
    place_marker "findutils"
fi

if ! marker_exists "flex" ; then
    unpack_pkg ${FLEX_PKG}
    cmd "cd ${PKG_WORKDIR}"
    cmd "./configure --prefix=/usr"
    cmd "make"
    cmd "make install"
    cmd "ln -sv libfl.a /usr/lib/libl.a"
    cmd 'cat > /usr/bin/lex << "EOF"
#!/bin/sh
# Begin /usr/bin/lex

exec /usr/bin/flex -l "$@"

# End /usr/bin/lex
EOF'
    cmd "chmod -v 755 /usr/bin/lex"
    cmd "cd .."
    cmd "rm -rf ${PKG_WORKDIR}"
    place_marker "flex"
fi

if ! marker_exists "grub" ; then
    unpack_pkg ${GRUB_PKG}
    get_patch_files ${GRUB_PATCH0} ${GRUB_PATCH1}
    cmd "cd ${PKG_WORKDIR}"
    cmd "patch -Np1 -i ../${PATCH_FILES[0]}"
    cmd "patch -Np1 -i ../${PATCH_FILES[1]}"
    cmd "./configure --prefix=/usr"
    cmd "make"
    cmd "make install"
    cmd "mkdir -v /boot/grub"
    cmd "cp -v /usr/lib/grub/i386-pc/stage{1,2} /boot/grub"
    cmd "cp -v /usr/lib/grub/i386-pc/reiserfs_stage1_5 /boot/grub"
    cmd "cd .."
    cmd "rm -rf ${PKG_WORKDIR}"
    place_marker "grub"
fi

if ! marker_exists "gettext" ; then
    unpack_pkg ${GETTEXT_PKG}
    cmd "cd ${PKG_WORKDIR}"
    cmd "./configure --prefix=/usr \\
    --docdir=/usr/share/doc/gettext-0.17"
    cmd "make"
    cmd "make install"
    cmd "cd .."
    cmd "rm -rf ${PKG_WORKDIR}"
    place_marker "gettext"
fi

if ! marker_exists "grep" ; then
    unpack_pkg ${GREP_PKG}
    get_patch_files ${GREP_PATCH0} ${GREP_PATCH1}
    cmd "cd ${PKG_WORKDIR}"
    cmd "patch -Np1 -i ../${PATCH_FILES[0]}"
    cmd "patch -Np1 -i ../${PATCH_FILES[1]}"
    cmd "./configure --prefix=/usr \\
    --bindir=/bin \\
    --without-included-regex"
    cmd "make"
    cmd "make install"
    cmd "cd .."
    cmd "rm -rf ${PKG_WORKDIR}"
    place_marker "grep"
fi

if ! marker_exists "groff" ; then
    unpack_pkg ${GROFF_PKG}
    get_patch_files ${GROFF_PATCH0}
    cmd "cd ${PKG_WORKDIR}"
    cmd "patch -Np1 -i ../${PATCH_FILES[0]}"
    cmd "sed -i -e 's/2010/002D/' -e 's/2212/002D/' \\
    -e 's/2018/0060/' -e 's/2019/0027/' font/devutf8/R.proto"
    cmd "PAGE=letter ./configure --prefix=/usr --enable-multibyte"
    cmd "make"
    cmd "make docdir=/usr/share/doc/groff-1.18.1.4 install"
    cmd "ln -sv eqn /usr/bin/geqn"
    cmd "ln -sv tbl /usr/bin/gtbl"
    cmd "cd .."
    cmd "rm -rf ${PKG_WORKDIR}"
    place_marker "groff"
fi

if ! marker_exists "gzip" ; then
    unpack_pkg ${GZIP_PKG}
    cmd "cd ${PKG_WORKDIR}"
    cmd "sed -i 's/futimens/gl_&/' gzip.c lib/utimens.{c,h}"
    cmd "./configure --prefix=/usr --bindir=/bin"
    cmd "make"
    cmd "make install"
    cmd "mv -v /bin/{gzexe,uncompress,zcmp,zdiff,zegrep} /usr/bin"
    cmd "mv -v /bin/{zfgrep,zforce,zgrep,zless,zmore,znew} /usr/bin"
    cmd "cd .."
    cmd "rm -rf ${PKG_WORKDIR}"
    place_marker "gzip"
fi

if ! marker_exists "inetutils" ; then
    unpack_pkg ${INETUTILS_PKG}
    get_patch_files ${INETUTILS_PATCH0}
    cmd "cd ${PKG_WORKDIR}"
    cmd "patch -Np1 -i ../${PATCH_FILES[0]}"
    cmd "sed -i 's@<sys/types.h>@<sys/types.h>\\n#include <stdlib.h>@' \\
    libicmp/icmp_timestamp.c"
    cmd "./configure --prefix=/usr --libexecdir=/usr/sbin \\
    --sysconfdir=/etc --localstatedir=/var \\
    --disable-ifconfig --disable-logger --disable-syslogd \\
    --disable-whois --disable-servers"
    cmd "make"
    cmd "make install"
    cmd "mv -v /usr/bin/ping /bin"
    cmd "cd .."
    cmd "rm -rf ${PKG_WORKDIR}"
    place_marker "inetutils"
fi

if ! marker_exists "iproute2" ; then
    unpack_pkg ${IPROUTE2_PKG}
    cmd "cd ${PKG_WORKDIR}"
    cmd "make DESTDIR= SBINDIR=/sbin"
    cmd "make DESTDIR= SBINDIR=/sbin MANDIR=/usr/share/man \\
    DOCDIR=/usr/share/doc/iproute2-2.6.26 install"
    cmd "mv -v /sbin/arpd /usr/sbin"
    cmd "cd .."
    cmd "rm -rf ${PKG_WORKDIR}"
    place_marker "iproute2"
fi

if ! marker_exists "kbd" ; then
    unpack_pkg ${KBD_PKG}
    get_patch_files ${KBD_PATCH0}
    cmd "cd ${PKG_WORKDIR}"
    cmd "patch -Np1 -i ../${PATCH_FILES[0]}"
    cmd "sed -i -e '1i KEYCODES_PROGS = @KEYCODES_PROGS@' \\
    -e '1i RESIZECONS_PROGS = @RESIZECONS_PROGS@' src/Makefile.in"
    cmd 'var=OPTIONAL_PROGS'
    cmd 'sed -i "s/ifdef $var/ifeq (\$($var),yes)/" man/Makefile.in'
    cmd 'unset var'
    cmd "./configure --datadir=/lib/kbd"
    cmd "make"
    cmd "make install"
    cmd "mv -v /usr/bin/{kbd_mode,loadkeys,openvt,setfont} /bin"
    cmd "cd .."
    cmd "rm -rf ${PKG_WORKDIR}"
    place_marker "kbd"
fi

if ! marker_exists "less" ; then
    unpack_pkg ${LESS_PKG}
    cmd "cd ${PKG_WORKDIR}"
    cmd "./configure --prefix=/usr --sysconfdir=/etc"
    cmd "make"
    cmd "make install"
    cmd "cd .."
    cmd "rm -rf ${PKG_WORKDIR}"
    place_marker "less"
fi

if ! marker_exists "make" ; then
    unpack_pkg ${MAKE_PKG}
    cmd "cd ${PKG_WORKDIR}"
    cmd "./configure --prefix=/usr"
    cmd "make"
    cmd "make install"
    cmd "cd .."
    cmd "rm -rf ${PKG_WORKDIR}"
    place_marker "make"
fi

if ! marker_exists "man-db" ; then
    unpack_pkg ${MAN_DB_PKG}
    cmd "cd ${PKG_WORKDIR}"
    echo_cmd "sed -i -e '\\%%\\\\t/usr/man%%d' -e '\\%%\\\\t/usr/local/man%%d' src/man_db.conf.in"
    sed -i -e '\%\t/usr/man%d' -e '\%\t/usr/local/man%d' src/man_db.conf.in
    cmd './configure --prefix=/usr --libexecdir=/usr/lib \
    --sysconfdir=/etc --disable-setuid \
    --enable-mb-groff --with-browser=/usr/bin/lynx \
    --with-col=/usr/bin/col --with-vgrind=/usr/bin/vgrind \
    --with-grap=/usr/bin/grap'
    cmd "make"
    cmd "make install"
    cmd 'cat > convert-mans << "EOF"
#!/bin/sh -e
FROM="$1"
TO="$2"
shift ; shift
while [ $# -gt 0 ]
do
        FILE="$1"
        shift
        iconv -f "$FROM" -t "$TO" "$FILE" >.tmp.iconv
        mv .tmp.iconv "$FILE"
done
EOF'
    cmd "install -m755 convert-mans /usr/bin"
    cmd "cd .."
    cmd "rm -rf ${PKG_WORKDIR}"
    place_marker "man-db"
fi

if ! marker_exists "module-init-tools" ; then
    unpack_pkg ${MODULE_INIT_TOOLS_PKG}
    get_patch_files ${MODULE_INIT_TOOLS_PATCH0}
    cmd "cd ${PKG_WORKDIR}"
    cmd "patch -Np1 -i ../${PATCH_FILES[0]}"
    cmd "./configure --prefix=/ --enable-zlib --mandir=/usr/share/man"
    cmd "make"
    cmd "make INSTALL=install install"
    cmd "cd .."
    cmd "rm -rf ${PKG_WORKDIR}"
    place_marker "module-init-tools"
fi

if ! marker_exists "patch" ; then
    unpack_pkg ${PATCH_PKG}
    cmd "cd ${PKG_WORKDIR}"
    cmd "./configure --prefix=/usr"
    cmd "make"
    cmd "make install"
    cmd "cd .."
    cmd "rm -rf ${PKG_WORKDIR}"
    place_marker "patch"
fi

if ! marker_exists "psmisc" ; then
    unpack_pkg ${PSMISC_PKG}
    cmd "cd ${PKG_WORKDIR}"
    cmd "./configure --prefix=/usr --exec-prefix=\"\""
    cmd "make"
    cmd "make install"
    cmd "mv -v /bin/pstree* /usr/bin"
    cmd "cd .."
    cmd "rm -rf ${PKG_WORKDIR}"
    place_marker "psmisc"
fi

if ! marker_exists "shadow" ; then
    unpack_pkg ${SHADOW_PKG}
    cmd "cd ${PKG_WORKDIR}"
    cmd "sed -i 's/groups\$(EXEEXT) //' src/Makefile.in"
    cmd "find man -name Makefile.in -exec sed -i 's/groups\\.1 / /' {} \;"
    cmd "sed -i -e 's/ ko//' -e 's/ zh_CN zh_TW//' man/Makefile.in"
    cmd "for i in de es fi fr id it pt_BR; do
convert-mans UTF-8 ISO-8859-1 man/\${i}/*.?
done"
    cmd "for i in cs hu pl; do
convert-mans UTF-8 ISO-8859-2 man/\${i}/*.?
done"
    cmd "convert-mans UTF-8 EUC-JP man/ja/*.?"
    cmd "convert-mans UTF-8 KOI8-R man/ru/*.?"
    cmd "convert-mans UTF-8 ISO-8859-9 man/tr/*.?"
    cmd "sed -i -e 's@#ENCRYPT_METHOD DES@ENCRYPT_METHOD MD5@' \\
    -e 's@/var/spool/mail@/var/mail@' etc/login.defs"
    cmd "./configure --sysconfdir=/etc"
    cmd "make"
    cmd "make install"
    cmd "mv -v /usr/bin/passwd /bin"
    cmd "pwconv"
    cmd "grpconv"
    cmd "sed -i 's/yes/no/' /etc/default/useradd"
    cmd "cd .."
    cmd "rm -rf ${PKG_WORKDIR}"
    place_marker "shadow"
fi

if ! marker_exists "sysklogd" ; then
    unpack_pkg ${SYSKLOGD_PKG}
    cmd "cd ${PKG_WORKDIR}"
    cmd "make"
    cmd "make install"
    cmd 'cat > /etc/syslog.conf << "EOF"
# Begin /etc/syslog.conf

auth,authpriv.* -/var/log/auth.log
*.*;auth,authpriv.none -/var/log/sys.log
daemon.* -/var/log/daemon.log
kern.* -/var/log/kern.log
mail.* -/var/log/mail.log
user.* -/var/log/user.log
*.emerg *

# End /etc/syslog.conf
EOF'
    cmd "cd .."
    cmd "rm -rf ${PKG_WORKDIR}"
    place_marker "sysklogd"
fi

if ! marker_exists "sysvinit" ; then
    unpack_pkg ${SYSVINIT_PKG}
    cmd "cd ${PKG_WORKDIR}"
    cmd "sed -i 's@Sending processes@& configured via /etc/inittab@g' \\
    src/init.c"
    cmd "sed -i -e 's/utmpdump wall/utmpdump/' \
       -e 's/mountpoint.1 wall.1/mountpoint.1/' src/Makefile"
    cmd "make -C src"
    cmd "make -C src install"
    cmd 'cat > /etc/inittab << "EOF"
# Begin /etc/inittab

id:3:initdefault:

si::sysinit:/etc/rc.d/init.d/rc sysinit

l0:0:wait:/etc/rc.d/init.d/rc 0
l1:S1:wait:/etc/rc.d/init.d/rc 1
l2:2:wait:/etc/rc.d/init.d/rc 2
l3:3:wait:/etc/rc.d/init.d/rc 3
l4:4:wait:/etc/rc.d/init.d/rc 4
l5:5:wait:/etc/rc.d/init.d/rc 5
l6:6:wait:/etc/rc.d/init.d/rc 6

ca:12345:ctrlaltdel:/sbin/shutdown -t1 -a -r now

su:S016:once:/sbin/sulogin

1:2345:respawn:/sbin/agetty tty1 9600
2:2345:respawn:/sbin/agetty tty2 9600
3:2345:respawn:/sbin/agetty tty3 9600
4:2345:respawn:/sbin/agetty tty4 9600
5:2345:respawn:/sbin/agetty tty5 9600
6:2345:respawn:/sbin/agetty tty6 9600

# End /etc/inittab
EOF'
    cmd "cd .."
    cmd "rm -rf ${PKG_WORKDIR}"
    place_marker "sysvinit"
fi

if ! marker_exists "tar" ; then
    unpack_pkg ${TAR_PKG}
    cmd "cd ${PKG_WORKDIR}"
    cmd "./configure --prefix=/usr --bindir=/bin --libexecdir=/usr/sbin"
    cmd "make"
    cmd "make install"
    cmd "cd .."
    cmd "rm -rf ${PKG_WORKDIR}"
    place_marker "tar"
fi

if ! marker_exists "texinfo" ; then
    unpack_pkg ${TEXINFO_PKG}
    cmd "cd ${PKG_WORKDIR}"
    cmd "./configure --prefix=/usr"
    cmd "make"
    cmd "make install"
    cmd "cd .."
    cmd "rm -rf ${PKG_WORKDIR}"
    place_marker "texinfo"
fi

if ! marker_exists "udev" ; then
    unpack_pkg ${UDEV_PKG}
    cmd "cd ${PKG_WORKDIR}"
    cmd "tar -xvf ../udev-config-20081015.tar.bz2"
    cmd 'install -dv /lib/{firmware,udev/devices/{pts,shm}}'
    cmd 'mknod -m0666 /lib/udev/devices/null c 1 3'
    cmd 'mknod -m0600 /lib/udev/devices/kmsg c 1 11'
    cmd 'ln -sv /proc/self/fd /lib/udev/devices/fd'
    cmd 'ln -sv /proc/self/fd/0 /lib/udev/devices/stdin'
    cmd 'ln -sv /proc/self/fd/1 /lib/udev/devices/stdout'
    cmd 'ln -sv /proc/self/fd/2 /lib/udev/devices/stderr'
    cmd 'ln -sv /proc/kcore /lib/udev/devices/core'
    cmd './configure --prefix=/usr \
            --exec-prefix= \
            --sysconfdir=/etc'
    cmd "make"
    cmd "make install"
    cmd "install -m644 -v rules/packages/64-*.rules \\
    /lib/udev/rules.d/"
    cmd 'install -m644 -v rules/packages/40-pilot-links.rules \
    /lib/udev/rules.d/'
    cmd "cd udev-config-20081015"
    cmd "make install"
    cmd "make install-doc"
    cmd "make install-extra-doc"
    cmd "cd .."
    cmd "install -m644 -v -D docs/writing_udev_rules/index.html \\
    /usr/share/doc/udev-130/index.html"
    cmd "cd .."
    cmd "rm -rf ${PKG_WORKDIR}"
    place_marker "udev"
fi

if ! marker_exists "util-linux" ; then
    unpack_pkg ${UTIL_LINUX_PKG}
    cmd "cd ${PKG_WORKDIR}"
    cmd "sed -e 's@etc/adjtime@var/lib/hwclock/adjtime@g' \\
    -i \$(grep -rl '/etc/adjtime' .)"
    cmd "mkdir -pv /var/lib/hwclock"
    cmd "./configure --enable-arch --enable-partx --enable-write"
    cmd "make"
    cmd "make install"
    cmd "cd .."
    cmd "rm -rf ${PKG_WORKDIR}"
    place_marker "util-linux"
fi

if ! marker_exists "joe" ; then
    unpack_pkg ${JOE_PKG}
    cmd "cd ${PKG_WORKDIR}"
    cmd "./configure --sysconfdir=/etc --prefix=/usr"
    cmd "make"
    cmd "make install"
    cmd "cd .."
    cmd "rm -rf ${PKG_WORKDIR}"
    place_marker "joe"
fi

if ! marker_exists "wget" ; then
    unpack_pkg ${WGET_PKG}
    cmd "cd ${PKG_WORKDIR}"
    cmd "./configure --prefix=/usr --sysconfdir=/etc"
    cmd "make"
    cmd "make install"
    cmd "cd .."
    cmd "rm -rf ${PKG_WORKDIR}"
    place_marker "wget"
fi

if ! marker_exists "lfs-bootscripts" ; then
    unpack_pkg ${LFS_BOOTSCRIPTS_PKG}
    cmd "cd ${PKG_WORKDIR}"
    cmd "make install"
    cmd "cd .."
    cmd "rm -rf ${PKG_WORKDIR}"
    place_marker "lfs-bootscripts"
fi

# Chroot w/o /tools in path?

if ! marker_exists "system-bootscripts" ; then
    cmd "cat > /etc/sysconfig/clock << \"EOF\"
# Begin /etc/sysconfig/clock

UTC=1

# End /etc/sysconfig/clock
EOF"
    cmd 'cat > /etc/inputrc << "EOF"
# Begin /etc/inputrc
# Modified by Chris Lynn <roryo@roryo.dynup.net>

# Allow the command prompt to wrap to the next line
set horizontal-scroll-mode Off

# Enable 8bit input
set meta-flag On
set input-meta On

# Turns off 8th bit stripping
set convert-meta Off

# Keep the 8th bit for display
set output-meta On

# none, visible or audible
set bell-style none

# All of the following map the escape sequence of the value
# contained in the 1st argument to the readline specific functions
"\\eOd": backward-word
"\\eOc": forward-word

# for linux console
"\\e[1~": beginning-of-line
"\\e[4~": end-of-line
"\\e[5~": beginning-of-history
"\\e[6~": end-of-history
"\\e[3~": delete-char
"\\e[2~": quoted-insert

# for xterm
"\\eOH": beginning-of-line
"\\eOF": end-of-line

# for Konsole
"\\e[H": beginning-of-line
"\\e[F": end-of-line

# End /etc/inputrc
EOF'
    # Secretly fix the file.
    sed -i 's@\\\\@\\@g' /etc/inputrc

    cmd 'cat > /etc/profile << "EOF"
# Begin /etc/profile

export LANG=en_US.ISO-8859-1

PS1=\"[\h:\w]\n> \"

# End /etc/profile
EOF'

    cmd 'echo "HOSTNAME=pris" > /etc/sysconfig/network'

    cmd 'cat > /etc/hosts << "EOF"
# Begin /etc/hosts

127.0.0.1 localhost
#<192.168.1.1> <HOSTNAME.example.org> [alias1] [alias2 ...]

192.168.0.4   roy   roy.valis

# End /etc/hosts
EOF'

    cmd "for NIC in /sys/class/net/* ; do
    INTERFACE=\${NIC##*/} udevadm test --action=add --subsystem=net \$NIC
done"
    cmd "cat /etc/udev/rules.d/70-persistent-net.rules"
    cmd "cd /etc/sysconfig/network-devices"
    cmd "mkdir -v ifconfig.eth0"
    cmd 'cat > ifconfig.eth0/ipv4 << "EOF"
ONBOOT=yes
SERVICE=ipv4-static
IP=192.168.0.5
GATEWAY=192.168.0.1
PREFIX=24
BROADCAST=192.168.0.255
EOF'
    cmd "cd /src"

    cmd 'cat > /etc/resolv.conf << "EOF"
# Begin /etc/resolv.conf

domain valis
nameserver 24.29.103.10
nameserver 24.29.103.11

# End /etc/resolv.conf
EOF'

    cmd 'cat > /etc/fstab << "EOF"
# Begin /etc/fstab

# file system  mount-point  type     options         dump  fsck
#                                                          order

/dev/hda1      /            reiserfs noatime,notail  1     1
/dev/hdb3      /pris        reiserfs noatime         0     0
/dev/hdb1      swap         swap     pri=1           0     0
/dev/sr0       /media/cdrom auto     noauto,ro       0     0
proc           /proc        proc     defaults        0     0
sysfs          /sys         sysfs    defaults        0     0
devpts         /dev/pts     devpts   gid=4,mode=620  0     0
shm            /dev/shm     tmpfs    defaults        0     0
# End /etc/fstab
EOF'

    cmd 'cat > /etc/rc.d/init.d/local << "EOF"
#!/bin/bash
# Begin /etc/rc.d/init.d/local

if [ -x /etc/rc.local ]; then
    /etc/rc.local
fi

# End /etc/rc.d/init.d/local
EOF'
    cmd "chmod -v 0754 /etc/rc.d/init.d/local"
    cmd "ln -sv ../init.d/local /etc/rc.d/rc2.d/S99local"
    cmd "ln -sv ../init.d/local /etc/rc.d/rc3.d/S99local"
    cmd "ln -sv ../init.d/local /etc/rc.d/rc4.d/S99local"
    cmd "ln -sv ../init.d/local /etc/rc.d/rc5.d/S99local"

    cmd 'cat > /etc/rc.local << "EOF"
#!/bin/bash
/pris/pris-rebuild-a.sh 1>>/dev/null &
EOF'
    cmd "chmod -v 0754 /etc/rc.local"

    place_marker "system-bootscripts"
fi

exit 0

if ! marker_exists "linux" ; then
    unpack_pkg ${LINUX_PKG}
    cmd "cd ${PKG_WORKDIR}"
    cmd "LINUX_VER=${PKG_WORKDIR#linux-}"
    cmd "make mrproper"

    # cmd "cp -v /pris/copy-to-mount/config-${LINUX_VER} .config"
    cmd "gunzip -c /proc/config.gz > .config"

    cmd "make"
    cmd "make modules_install"
    cmd "cp -v arch/i386/boot/bzImage /boot/lfskernel-${LINUX_VER}"
    cmd "cp -v System.map /boot/System.map-${LINUX_VER}"
    cmd "cp -v .config /boot/config-${LINUX_VER}"
    cmd "cat > /boot/grub/menu.lst << \"EOF\"
# Begin /boot/grub/menu.lst

# By default boot the first menu entry.
default 0

# Allow 5 seconds before booting the default.
timeout 5

# The first entry is for LFS.
title LFS 6.3
root (hd0,0)
kernel /boot/lfskernel-${LINUX_VER} root=/dev/hda1
EOF"
    cmd "mkdir -v /etc/grub"
    cmd "ln -sv /boot/grub/menu.lst /etc/grub"
    cmd "cd .."
    cmd "rm -rf ${PKG_WORKDIR}"
    place_marker "linux"
fi

if ! marker_exists "lfs-release" ; then
    cmd "echo 6.4 > /etc/lfs-release"
    place_marker "lfs-release"
fi

if ! marker_exists "blfs-bootscripts" ; then
    download_blfs_pkg ${BLFS_BOOTSCRIPTS_PKG}
    unpack_pkg ${BLFS_BOOTSCRIPTS_PKG}
    place_marker "blfs-bootscripts"
else
    get_pkg_file ${BLFS_BOOTSCRIPTS_PKG}
    get_pkg_workdir ${PKG_FILE}
fi
declare BLFS_BOOTSCRIPTS=${PKG_WORKDIR}

if ! marker_exists "reiserfsprogs" ; then
    download_blfs_pkg ${REISERFSPROGS_PKG}
    unpack_pkg ${REISERFSPROGS_PKG}
    cmd "cd ${PKG_WORKDIR}"
    cmd "./configure --prefix=/usr --sbindir=/sbin"
    cmd "make"
    cmd "make install"
    cmd "ln -svf reiserfsck /sbin/fsck.reiserfs"
    cmd "ln -svf mkreiserfs /sbin/mkfs.reiserfs"
    cmd "cd .."
    cmd "rm -rf ${PKG_WORKDIR}"
    place_marker "reiserfsprogs"
fi

if ! marker_exists "sysfsutils" ; then
    download_blfs_pkg ${SYSFSUTILS_PKG}
    unpack_pkg ${SYSFSUTILS_PKG}
    cmd "cd ${PKG_WORKDIR}"
    cmd "./configure --prefix=/usr --libdir=/lib"
    cmd "make"
    cmd "make install"
    cmd "cd .."
    cmd "rm -rf ${PKG_WORKDIR}"
    place_marker "sysfsutils"
fi

if ! marker_exists "pcmciautils" ; then
    download_blfs_pkg ${PCMCIAUTILS_PKG}
    unpack_pkg ${PCMCIAUTILS_PKG}
    cmd "cd ${PKG_WORKDIR}"
    cmd "sed -i 's/MODALIAS/ENV{MODALIAS}/g' udev/rules-base"
    cmd ">udev/rules-modprobe"
    cmd "make"
    cmd "make SYMLINK=\"ln -sf\" install"
    cmd "cd .."
    cmd "rm -rf ${PKG_WORKDIR}"
    place_marker "pcmciautils"
fi

if ! marker_exists "openssl" ; then
    download_blfs_pkg ${OPENSSL_PKG}
    unpack_pkg ${OPENSSL_PKG}
    download_blfs_patches ${OPENSSL_PATCH0}
    cmd "cd ${PKG_WORKDIR}"
    cmd "patch -Np1 -i ../${PATCH_FILES[0]}"
    cmd "./config --openssldir=/etc/ssl --prefix=/usr shared"
    cmd "make MANDIR=/usr/share/man"
    cmd "make MANDIR=/usr/share/man install"
    cmd "cp -v -r certs /etc/ssl"
    cmd "cd .."
    cmd "rm -rf ${PKG_WORKDIR}"
    place_marker "openssl"
fi

if ! marker_exists "openssh" ; then
    download_blfs_pkg ${OPENSSH_PKG}
    unpack_pkg ${OPENSSH_PKG}
    cmd "cd ${PKG_WORKDIR}"
    cmd "install -v -m700 -d /var/lib/sshd"
    cmd "chown -v root:sys /var/lib/sshd"
    cmd "groupadd -g 50 sshd"
    cmd "useradd -c 'sshd PrivSep' -d /var/lib/sshd -g sshd \\
    -s /bin/false -u 50 sshd"
    cmd "sed -i 's@ -ldes@@' configure"
    cmd \
    "./configure --prefix=/usr --sysconfdir=/etc/ssh --datadir=/usr/share/sshd \\
    --libexecdir=/usr/lib/openssh --with-md5-passwords \\
    --with-privsep-path=/var/lib/sshd \\
    --with-xauth=/usr/bin/xauth"
    cmd "make"
    cmd "make install"
    cmd "cd ../${BLFS_BOOTSCRIPTS}"
    cmd "make install-sshd"
    cmd "cd .."
    cmd "rm -rf ${PKG_WORKDIR}"
    place_marker "openssh"
fi

if ! marker_exists "bash-profile" ; then
    cmd "cat > /etc/profile << \"EOF\"
# Begin /etc/profile
# Written for Beyond Linux From Scratch
# by James Robertson <jameswrobertson@earthlink.net>
# modifications by Dagmar d'Surreal <rivyqntzne@pbzpnfg.arg>

# System wide environment variables and startup programs.

# System wide aliases and functions should go in /etc/bashrc.  Personal
# environment variables and startup programs should go into
# ~/.bash_profile.  Personal aliases and functions should go into
# ~/.bashrc.

# Functions to help us manage paths.  Second argument is the name of the
# path variable to be modified (default: PATH)
pathremove () {
        local IFS=':'
        local NEWPATH
        local DIR
        local PATHVARIABLE=\${2:-PATH}
        for DIR in \${!PATHVARIABLE} ; do
                if [ \"\$DIR\" != \"\$1\" ] ; then
                  NEWPATH=\${NEWPATH:+\$NEWPATH:}\$DIR
                fi
        done
        export \$PATHVARIABLE=\"\$NEWPATH\"
}

pathprepend () {
        pathremove \$1 \$2
        local PATHVARIABLE=\${2:-PATH}
        export \$PATHVARIABLE=\"\$1\${!PATHVARIABLE:+:\${!PATHVARIABLE}}\"
}

pathappend () {
        pathremove \$1 \$2
        local PATHVARIABLE=\${2:-PATH}
        export \$PATHVARIABLE=\"\${!PATHVARIABLE:+\${!PATHVARIABLE}:}\$1\"
}


# Set the initial path
export PATH=/bin:/usr/bin

if [ \$EUID -eq 0 ] ; then
        pathappend /sbin:/usr/sbin
        unset HISTFILE
fi

# Setup some environment variables.
export HISTSIZE=1000
export HISTIGNORE=\"&:[bf]g:exit\"

PS1=\"[\h:\w]\n> \"

for script in /etc/profile.d/*.sh ; do
        if [ -r \$script ] ; then
                . \$script
        fi
done

# Now to clean up
unset pathremove pathprepend pathappend

# End /etc/profile
EOF"
    cmd "install --directory --mode=0755 --owner=root --group=root /etc/profile.d"
    cmd 'cat > /etc/profile.d/extrapaths.sh << "EOF"
if [ -d /usr/local/lib/pkgconfig ] ; then
        pathappend /usr/local/lib/pkgconfig PKG_CONFIG_PATH
fi
if [ -d /usr/local/bin ]; then
        pathprepend /usr/local/bin
fi
if [ -d /usr/local/sbin -a $EUID -eq 0 ]; then
        pathprepend /usr/local/sbin
fi

if [ -d ~/bin ]; then
        pathprepend ~/bin
fi
EOF'
    cmd 'cat > /etc/profile.d/readline.sh << "EOF"
# Setup the INPUTRC environment variable.
if [ -z "$INPUTRC" -a ! -f "$HOME/.inputrc" ] ; then
        INPUTRC=/etc/inputrc
fi
export INPUTRC
EOF'
    cmd 'cat > /etc/profile.d/umask.sh << "EOF"
# By default we want the umask to get set.
if [ "$(id -gn)" = "$(id -un)" -a $EUID -gt 99 ] ; then
  umask 002
else
  umask 022
fi
EOF'
    cmd 'cat > /etc/profile.d/X.sh << "EOF"
if [ -x /usr/X11R6/bin/X ]; then
        pathappend /usr/X11R6/bin
fi
if [ -d /usr/X11R6/lib/pkgconfig ] ; then
        pathappend /usr/X11R6/lib/pkgconfig PKG_CONFIG_PATH
fi
EOF'
    cmd 'cat > /etc/profile.d/i18n.sh << "EOF"
# Set up i18n variables
export LANG=en_US.ISO-8859-1
EOF'
    cmd "cat > /etc/bashrc << \"EOF\"
# Begin /etc/bashrc
# Written for Beyond Linux From Scratch
# by James Robertson <jameswrobertson@earthlink.net>
# updated by Bruce Dubbs <bdubbs@linuxfromscratch.org>

# System wide aliases and functions.

# System wide environment variables and startup programs should go into
# /etc/profile.  Personal environment variables and startup programs
# should go into ~/.bash_profile.  Personal aliases and functions should
# go into ~/.bashrc

# Provides a colored /bin/ls command.  Used in conjunction with code in
# /etc/profile.

alias ls='ls --color=auto'

# Provides prompt for non-login shells, specifically shells started
# in the X environment. [Review the LFS archive thread titled
# PS1 Environment Variable for a great case study behind this script
# addendum.]

PS1=\"[\h:\w]\n> \"

# End /etc/bashrc
EOF"
    cmd "cd ${BLFS_BOOTSCRIPTS}"
    cmd "make install-random"
    cmd "cd .."
    place_marker "bash-profile"
fi

if ! marker_exists "pcre" ; then
    download_blfs_pkg ${PCRE_PKG}
    unpack_pkg ${PCRE_PKG}
    download_blfs_patches ${PCRE_PATCH0} ${PCRE_PATCH1}
    cmd "cd ${PKG_WORKDIR}"
    cmd "patch -Np1 -i ../${PATCH_FILES[0]}"
    cmd "patch -Np1 -i ../${PATCH_FILES[1]}"
    cmd \
    "./configure --prefix=/usr --docdir=/usr/share/doc/pcre-7.6 \\
    --enable-utf8 --enable-pcregrep-libz --enable-pcregrep-libbz2"
    cmd "make"
    cmd "make install"
    cmd "cd .."
    cmd "rm -rf ${PKG_WORKDIR}"
    place_marker "pcre"
fi

if ! marker_exists "zsh" ; then
    download_blfs_pkg ${ZSH_PKG}
    unpack_pkg ${ZSH_PKG}
    cmd "cd ${PKG_WORKDIR}"
    # The added option '--with-tcsetpgrp' needed when no tty present 
    # (as when run from this script).
    cmd \
    "./configure --prefix=/usr --bindir=/bin \\
    --sysconfdir=/etc/zsh --enable-etcdir=/etc/zsh \\
    --enable-pcre --with-tcsetpgrp"
    cmd "make"
    cmd "make install"
    cmd 'cat >> /etc/shells << "EOF"
/usr/bin/zsh
/usr/bin/zsh-4.3.6
EOF'
    cmd "cd .."
    cmd "rm -rf ${PKG_WORKDIR}"
    place_marker "zsh"
fi

if ! marker_exists "hdparm" ; then
    download_blfs_pkg ${HDPARM_PKG}
    unpack_pkg ${HDPARM_PKG}
    cmd "cd ${PKG_WORKDIR}"
    cmd "make"
    cmd "make install"
    cmd "cd .."
    cmd "rm -rf ${PKG_WORKDIR}"
    place_marker "hdparm"
fi

if ! marker_exists "popt" ; then
    download_blfs_pkg ${POPT_PKG}
    unpack_pkg ${POPT_PKG}
    cmd "cd ${PKG_WORKDIR}"
    cmd 'sed -i -e "/*origOptString ==/c 0)" popt.c'
    cmd "./configure --prefix=/usr"
    cmd "make"
    cmd "make install"
    cmd "cd .."
    cmd "rm -rf ${PKG_WORKDIR}"
    place_marker "popt"
fi

if ! marker_exists "rsync" ; then
    download_blfs_pkg ${RSYNC_PKG}
    unpack_pkg ${RSYNC_PKG}
    cmd "cd ${PKG_WORKDIR}"
    cmd "./configure --prefix=/usr"
    cmd "make"
    cmd "make install"
    cmd "cd .."
    cmd "rm -rf ${PKG_WORKDIR}"
    place_marker "rsync"
fi

if ! marker_exists "which" ; then
    download_blfs_pkg ${WHICH_PKG}
    unpack_pkg ${WHICH_PKG}
    cmd "cd ${PKG_WORKDIR}"
    cmd "./configure --prefix=/usr"
    cmd "make"
    cmd "make install"
    cmd "cd .."
    cmd "rm -rf ${PKG_WORKDIR}"
    place_marker "which"
fi

if ! marker_exists "ntp" ; then
    download_blfs_pkg ${NTP_PKG}
    unpack_pkg ${NTP_PKG}
    cmd "cd ${PKG_WORKDIR}"
    cmd \
    "./configure --prefix=/usr --sysconfdir=/etc \\
    --with-binsubdir=sbin"
    cmd "make"
    cmd "make install"
    cmd 'cat > /etc/ntp.conf << "EOF"
# Africa
server tock.nml.csir.co.za

# Asia
server 0.asia.pool.ntp.org

# Australia
server 0.oceania.pool.ntp.org

# Europe
server 0.europe.pool.ntp.org

# North America
server 0.north-america.pool.ntp.org

# South America
server 2.south-america.pool.ntp.org

driftfile /var/cache/ntp.drift
pidfile   /var/run/ntpd.pid
EOF'
    cmd 'cat > /etc/rc.d/init.d/ntpd-onetime << "EOF"
#!/bin/sh
# Begin $rc_base/init.d/ntpd-onetime

. /etc/sysconfig/rc
. $rc_functions

case "$1" in
        start)
                boot_mesg "Running ntpd-onetime..."
                ntpd -gq 
                ;;

        *)
                echo "Usage: $0 start"
                exit 1
                ;;
esac

# End $rc_base/init.d/ntpd-onetime
EOF'
    cmd "chmod -v 754 /etc/rc.d/init.d/ntpd-onetime"
    cmd "ln -sv ../init.d/ntpd-onetime /etc/rc.d/rc3.d/S40ntpd-onetime"
    cmd "ln -v -sf ../init.d/setclock /etc/rc.d/rc0.d/K46setclock"
    cmd "ln -v -sf ../init.d/setclock /etc/rc.d/rc6.d/K46setclock"
    cmd "cd .."
    cmd "rm -rf ${PKG_WORKDIR}"
    place_marker "ntp"
fi

# if ! marker_exists "alsa-lib" ; then
#     download_blfs_pkg ${ALSA_LIB_PKG}
#     unpack_pkg ${ALSA_LIB_PKG}
#     cmd "cd ${PKG_WORKDIR}"
#     cmd "./configure --enable-static"
#     cmd "make"
#     cmd "make install"
#     cmd "cd .."
#     cmd "rm -rf ${PKG_WORKDIR}"
#     place_marker "alsa-lib"
# fi
# 
# if ! marker_exists "alsa-utils" ; then
#     download_blfs_pkg ${ALSA_UTILS_PKG}
#     unpack_pkg ${ALSA_UTILS_PKG}
#     cmd "cd ${PKG_WORKDIR}"
#     cmd "./configure --prefix=/usr"
#     cmd "make"
#     cmd "make install"
#     cmd "cd ../${BLFS_BOOTSCRIPTS}"
#     cmd "make install-alsa"
#     cmd "touch /etc/asound.state"
#     cmd "alsactl store"
#     cmd 'cat > /etc/udev/rules.d/40-alsa.rules << "EOF"
# # /etc/udev/rules.d/40-alsa.rules
# 
# # When a sound device is detected, restore the volume settings
# KERNEL=="controlC[0-9]*", ACTION=="add", RUN+="/usr/sbin/alsactl restore %n"
# EOF'
#     cmd "chmod -v 644 /etc/udev/rules.d/40-alsa.rules"
#     cmd "cd .."
#     cmd "rm -rf ${PKG_WORKDIR}"
#     place_marker "alsa-utils"
# fi

remove_pid "pris-rebuild-d"

logout
exit 0
