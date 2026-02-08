#!/bin/bash

source "/pris/pris-fns.sh"
source "/pris/pris-pkgs.sh"

##############################################################################
## INIT                                                                     ##

write_pid "pris-rebuild-c"
# No support for color and bold.
export TERM=dumb

##############################################################################
## MAIN                                                                     ##

if ! marker_exists "base-sys" ; then
    cmd "mkdir -pv /{bin,boot,etc/opt,home,lib,mnt,opt}"
    cmd "mkdir -pv /{media/{floppy,cdrom},sbin,srv,var}"
    cmd "install -dv -m 0750 /root"
    cmd "install -dv -m 1777 /tmp /var/tmp"
    cmd "mkdir -pv /usr/{,local/}{bin,include,lib,sbin,src}"
    cmd "mkdir -pv /usr/{,local/}share/{doc,info,locale,man}"
    cmd "mkdir -v  /usr/{,local/}share/{misc,terminfo,zoneinfo}"
    cmd "mkdir -pv /usr/{,local/}share/man/man{1..8}"
    cmd "for dir in /usr /usr/local; do
ln -sv share/{man,doc,info} \$dir
done"
    cmd "mkdir -v /var/{lock,log,mail,run,spool}"
    cmd "mkdir -pv /var/{opt,cache,lib/{misc,locate},local}"

    cmd "ln -sv /tools/bin/{bash,cat,echo,grep,pwd,stty} /bin"
    cmd "ln -sv /tools/bin/perl /usr/bin"
    cmd "ln -sv /tools/lib/libgcc_s.so{,.1} /usr/lib"
    cmd "ln -sv /tools/lib/libstdc++.so{,.6} /usr/lib"
    cmd "ln -sv bash /bin/sh"

    cmd "touch /etc/mtab"

    cmd "cat > /etc/passwd << \"EOF\"
root:x:0:0:root:/root:/bin/bash
nobody:x:99:99:Unprivileged User:/dev/null:/bin/false
EOF"
    cmd "cat > /etc/group << \"EOF\"
root:x:0:
bin:x:1:
sys:x:2:
kmem:x:3:
tty:x:4:
tape:x:5:
daemon:x:6:
floppy:x:7:
disk:x:8:
lp:x:9:
uucp:x:10:
audio:x:11:
video:x:12:
utmp:x:13:
usb:x:14:
cdrom:x:15:
mail:x:34:
nogroup:x:99:
EOF"

    place_marker "base-sys"
fi

if ! marker_exists "logs" ; then
    cmd "touch /var/run/utmp /var/log/{btmp,lastlog,wtmp}"
    cmd "chgrp -v utmp /var/run/utmp /var/log/lastlog"
    cmd "chmod -v 664 /var/run/utmp /var/log/lastlog"
    place_marker "logs"
fi

cmd "cd /src"

if ! marker_exists "linux-headers" ; then
    unpack_pkg ${LINUX_PKG}
    cmd "cd ${PKG_WORKDIR}"
    cmd "make mrproper"
    cmd "make headers_check"
    cmd "make INSTALL_HDR_PATH=dest headers_install"
    cmd "cp -rv dest/include/* /usr/include"
    cmd "cd .."
    cmd "rm -rf ${PKG_WORKDIR}"
    place_marker "linux-headers"
fi

if ! marker_exists "man-pages" ; then
    unpack_pkg ${MAN_PAGES_PKG}
    cmd "cd ${PKG_WORKDIR}"
    cmd "make install"
    cmd "cd .."
    cmd "rm -rf ${PKG_WORKDIR}"
    place_marker "man-pages"
fi

if ! marker_exists "glibc" ; then
    [[ -e glibc-build ]] && rm -rf glibc-build
    unpack_pkg ${GLIBC_PKG}
    get_patch_files ${GLIBC_PATCH0} ${GLIBC_PATCH1}
    cmd "cd ${PKG_WORKDIR}"
    # cmd "tar -xvf ../glibc-libidn-2.5.1.tar.gz"
    # cmd "mv -v glibc-libidn-2.5.1 libidn"
    cmd "sed -i '/vi_VN.TCVN/d' localedata/SUPPORTED"
    cmd "patch -Np1 -i ../${PATCH_FILES[0]}"
    cmd "patch -Np1 -i ../${PATCH_FILES[1]}"
    cmd "sed -i 's|@BASH@|/bin/bash|' elf/ldd.bash.in"
    cmd "mkdir -v ../glibc-build"
    cmd "cd ../glibc-build"
    cmd 'echo "CFLAGS += -march=i486 -mtune=native" > configparms'
    cmd "../glibc-2.8-20080929/configure --prefix=/usr \\
    --disable-profile --enable-add-ons \\
    --enable-kernel=2.6.0 --libexecdir=/usr/lib/glibc"
    cmd "make"
    cmd 'cp -v ../glibc-2.8-20080929/iconvdata/gconv-modules iconvdata'
    echo_cmd "make -k check 2>&1 | tee glibc-check-log"
    make -k check 2>&1 | tee glibc-check-log | tee -a "${PRIS_LOG}"
    cmd "grep Error glibc-check-log"
    cmd "touch /etc/ld.so.conf"
    cmd "make install"
    cmd "mkdir -pv /usr/lib/locale"
    cmd "localedef -i cs_CZ -f UTF-8 cs_CZ.UTF-8"
    cmd "localedef -i de_DE -f ISO-8859-1 de_DE"
    cmd "localedef -i de_DE@euro -f ISO-8859-15 de_DE@euro"
    cmd "localedef -i de_DE -f UTF-8 de_DE.UTF-8"
    cmd "localedef -i en_HK -f ISO-8859-1 en_HK"
    cmd "localedef -i en_PH -f ISO-8859-1 en_PH"
    cmd "localedef -i en_US -f ISO-8859-1 en_US"
    cmd "localedef -i en_US -f UTF-8 en_US.UTF-8"
    cmd "localedef -i es_MX -f ISO-8859-1 es_MX"
    cmd "localedef -i fa_IR -f UTF-8 fa_IR"
    cmd "localedef -i fr_FR -f ISO-8859-1 fr_FR"
    cmd "localedef -i fr_FR@euro -f ISO-8859-15 fr_FR@euro"
    cmd "localedef -i fr_FR -f UTF-8 fr_FR.UTF-8"
    cmd "localedef -i it_IT -f ISO-8859-1 it_IT"
    cmd "localedef -i ja_JP -f EUC-JP ja_JP"
    cmd "localedef -i tr_TR -f UTF-8 tr_TR.UTF-8"
    cmd "cat > /etc/nsswitch.conf << "EOF"
# Begin /etc/nsswitch.conf

passwd: files
group: files
shadow: files

hosts: files dns
networks: files

protocols: files
services: files
ethers: files
rpc: files

# End /etc/nsswitch.conf
EOF"
    cmd "cp -v --remove-destination /usr/share/zoneinfo/America/New_York \\
    /etc/localtime"
    cmd "cat > /etc/ld.so.conf << \"EOF\"
# Begin /etc/ld.so.conf

/usr/local/lib
/opt/lib

# End /etc/ld.so.conf
EOF"
    cmd "cd .."
    cmd "rm -rf ${PKG_WORKDIR} glibc-build"
    place_marker "glibc"
fi

if ! marker_exists "readjust-toolchain" ; then
    cmd "mv -v /tools/bin/{ld,ld-old}"
    cmd "mv -v /tools/$(gcc -dumpmachine)/bin/{ld,ld-old}"
    cmd "mv -v /tools/bin/{ld-new,ld}"
    cmd "ln -sv /tools/bin/ld /tools/$(gcc -dumpmachine)/bin/ld"
    cmd "gcc -dumpspecs | sed \\
    -e 's@/tools/lib/ld-linux.so.2@/lib/ld-linux.so.2@g' \\
    -e '/\\*startfile_prefix_spec:/{n;s@.*@/usr/lib/ @}' \\
    -e '/\\*cpp:/{n;s@\$@ -isystem /usr/include@}' > \\
    \`dirname $(gcc --print-libgcc-file-name)\`/specs"
    cmd "echo 'main(){}' > dummy.c"
    cmd "cc dummy.c -v -Wl,--verbose &> dummy.log"
    cmd "readelf -l a.out | grep ': /lib'"
    cmd "grep -o '/usr/lib.*/crt[1in].*succeeded' dummy.log"
    cmd "grep -B1 '^ /usr/include' dummy.log"
    echo_cmd "grep 'SEARCH.*/usr/lib' dummy.log |sed 's|; |\\\\n|g'"
    eval_cmd "grep 'SEARCH.*/usr/lib' dummy.log |sed 's|; |\\n|g'"
    cmd "grep \"/lib/libc.so.6 \" dummy.log"
    cmd "grep found dummy.log"
    cmd "rm -v dummy.c a.out dummy.log"
    place_marker "readjust-toolchain"
fi

if ! marker_exists "binutils" ; then
    unpack_pkg ${BINUTILS_PKG}
    get_patch_files ${BINUTILS_PATCH0} ${BINUTILS_PATCH1}
    cmd "cd ${PKG_WORKDIR}"
    cmd "patch -Np1 -i ../${PATCH_FILES[0]}"
    cmd "patch -Np1 -i ../${PATCH_FILES[1]}"
    [[ -e ../binutils-build ]] && rm -rf ../binutils-build
    cmd "rm -fv etc/standards.info"
    cmd "sed -i.bak '/^INFO/s/standards.info //' etc/Makefile.in"
    cmd "mkdir -v ../binutils-build"
    cmd "cd ../binutils-build"
    cmd "../binutils-2.18/configure --prefix=/usr \\
    --enable-shared"
    cmd "make tooldir=/usr"
    cmd "make check"
    cmd "make tooldir=/usr install"
    cmd "cp -v ../binutils-2.18/include/libiberty.h /usr/include"
    cmd "cd .."
    cmd "rm -rf ${PKG_WORKDIR} binutils-build"
    place_marker "binutils"
fi

if ! marker_exists "gmp" ; then
    unpack_pkg ${GMP_PKG}
    cmd "cd ${PKG_WORKDIR}"
    cmd "./configure --prefix=/usr --enable-cxx --enable-mpbsd"
    echo_cmd "make check 2>&1 | tee gmp-check-log"
    make check 2>&1 | tee gmp-check-log | tee -a "${PRIS_LOG}"
    cmd "awk '/tests passed/{total+=\$2} ; END{print total}' gmp-check-log"
    cmd "make install"
    cmd "cd .."
    cmd "rm -rf ${PKG_WORKDIR}"
    place_marker "gmp"
fi

if ! marker_exists "mpfr" ; then
    unpack_pkg ${MPFR_PKG}
    cmd "cd ${PKG_WORKDIR}"
    cmd "./configure --prefix=/usr --enable-thread-safe"
    cmd "make"
    cmd "make check"
    cmd "make install"
    cmd "cd .."
    cmd "rm -rf ${PKG_WORKDIR}"
    place_marker "mpfr"
fi

if ! marker_exists "gcc" ; then
    [[ -e gcc-build ]] && rm -rf gcc-build
    unpack_pkg ${GCC_PKG}
    cmd "cd ${PKG_WORKDIR}"
    cmd "sed -i 's/install_to_\$(INSTALL_DEST) //' libiberty/Makefile.in"
    cmd "sed -i 's/^XCFLAGS =\$/& -fomit-frame-pointer/' gcc/Makefile.in"
    cmd "sed -i 's@\\./fixinc\\.sh@-c true@' gcc/Makefile.in"
    cmd "mkdir -v ../gcc-build"
    cmd "cd ../gcc-build"
    cmd "../gcc-4.3.2/configure --prefix=/usr \\
    --libexecdir=/usr/lib --enable-shared \\
    --enable-threads=posix --enable-__cxa_atexit \\
    --enable-clocale=gnu --enable-languages=c,c++ \\
    --disable-bootstrap"
    cmd "make"
    cmd "make -k check"
    cmd "../gcc-4.3.2/contrib/test_summary | grep -A7 Summ"
    cmd "make install"
    cmd "ln -sv ../usr/bin/cpp /lib"
    cmd "ln -sv gcc /usr/bin/cc"
    cmd "echo 'main(){}' > dummy.c"
    cmd "cc dummy.c -v -Wl,--verbose &> dummy.log"
    cmd "readelf -l a.out | grep ': /lib'"
    cmd "grep -o '/usr/lib.*/crt[1in].*succeeded' dummy.log"
    cmd "grep -B4 '^ /usr/include' dummy.log"
    echo_cmd "grep 'SEARCH.*/usr/lib' dummy.log |sed 's|; |\\\\n|g'"
    eval_cmd "grep 'SEARCH.*/usr/lib' dummy.log |sed 's|; |\\n|g'"
    cmd "grep \"/lib/libc.so.6 \" dummy.log"
    cmd "grep found dummy.log"
    cmd "rm -v dummy.c a.out dummy.log"
    cmd "cd .."
    cmd "rm -rf ${PKG_WORKDIR} gcc-build"
    place_marker "gcc"
fi

if ! marker_exists "berkeley-db" ; then
    unpack_pkg ${BERKELEY_DB_PKG}
    get_patch_files ${BERKELEY_DB_PATCH0}
    cmd "cd ${PKG_WORKDIR}"
    cmd "patch -Np1 -i ../${PATCH_FILES[0]}"
    cmd "cd build_unix"
    cmd "../dist/configure --prefix=/usr --enable-compat185 --enable-cxx"
    cmd "make"
    cmd "make docdir=/usr/share/doc/db-4.7.25 install"
    cmd "chown -Rv root:root /usr/share/doc/db-4.7.25"
    cmd "cd ../.."
    cmd "rm -rf ${PKG_WORKDIR}"
    place_marker "berkeley-db"
fi

if ! marker_exists "sed" ; then
    unpack_pkg ${SED_PKG}
    cmd "cd ${PKG_WORKDIR}"
    cmd "./configure --prefix=/usr --bindir=/bin --enable-html"
    cmd "make"
    cmd "make install"
    cmd "cd .."
    cmd "rm -rf ${PKG_WORKDIR}"
    place_marker "sed"
fi

if ! marker_exists "e2fsprogs" ; then
    unpack_pkg ${E2FSPROGS_PKG}
    cmd "cd ${PKG_WORKDIR}"
    cmd "sed -i -e 's@/bin/rm@/tools&@' lib/blkid/test_probe.in"
    cmd "mkdir -v build"
    cmd "cd build"
    cmd "../configure --prefix=/usr --with-root-prefix=\"\" \\
    --enable-elf-shlibs"
    cmd "make"
    cmd "make install"
    cmd "make install-libs"
    cmd 'chmod -v u+w /usr/lib/{libblkid,libcom_err,libe2p,libext2fs,libss,libuuid}.a'
    cmd "cd ../.."
    cmd "rm -rf ${PKG_WORKDIR}"
    place_marker "e2fsprogs"
fi

if ! marker_exists "coreutils" ; then
    unpack_pkg ${COREUTILS_PKG}
    get_patch_files ${COREUTILS_PATCH0} ${COREUTILS_PATCH1} ${COREUTILS_PATCH2}
    cmd "cd ${PKG_WORKDIR}"
    cmd "patch -Np1 -i ../${PATCH_FILES[0]}"
    cmd "patch -Np1 -i ../${PATCH_FILES[1]}"
    cmd "patch -Np1 -i ../${PATCH_FILES[2]}"
    cmd "./configure --prefix=/usr --enable-install-program=hostname --enable-no-install-program=kill,uptime"
    cmd "make"
    cmd "make install"
    cmd "mv -v /usr/bin/{cat,chgrp,chmod,chown,cp,date,dd,df,echo} /bin"
    cmd "mv -v /usr/bin/{false,hostname,ln,ls,mkdir,mknod,mv,pwd,readlink,rm} /bin"
    cmd "mv -v /usr/bin/{rmdir,stty,sync,true,uname} /bin"
    cmd "mv -v /usr/bin/chroot /usr/sbin"
    cmd "mv -v /usr/bin/{head,sleep,nice} /bin"
    cmd "cd .."
    cmd "rm -rf ${PKG_WORKDIR}"
    place_marker "coreutils"
fi

if ! marker_exists "iana-etc" ; then
    unpack_pkg ${IANA_ETC_PKG}
    cmd "cd ${PKG_WORKDIR}"
    cmd "make"
    cmd "make install"
    cmd "cd .."
    cmd "rm -rf ${PKG_WORKDIR}"
    place_marker "iana-etc"
fi

if ! marker_exists "m4" ; then
    unpack_pkg ${M4_PKG}
    cmd "cd ${PKG_WORKDIR}"
    cmd "./configure --prefix=/usr --enable-threads"
    cmd "make"
    cmd "make install"
    cmd "cd .."
    cmd "rm -rf ${PKG_WORKDIR}"
    place_marker "m4"
fi

if ! marker_exists "bison" ; then
    unpack_pkg ${BISON_PKG}
    cmd "cd ${PKG_WORKDIR}"
    cmd "./configure --prefix=/usr"
    cmd "make"
    cmd "echo '#define YYENABLE_NLS 1' >> config.h"
    cmd "make install"
    cmd "cd .."
    cmd "rm -rf ${PKG_WORKDIR}"
    place_marker "bison"
fi

if ! marker_exists "ncurses" ; then
    unpack_pkg ${NCURSES_PKG}
    get_patch_files ${NCURSES_PATCH0}
    cmd "cd ${PKG_WORKDIR}"
    cmd "patch -Np1 -i ../${PATCH_FILES[0]}"
    cmd "./configure --prefix=/usr --with-shared --without-debug --enable-widec"
    cmd "make"
    cmd "make install"
    cmd "chmod -v 644 /usr/lib/libncurses++w.a"
    cmd "mv -v /usr/lib/libncursesw.so.5* /lib"
    cmd "ln -sfv ../../lib/libncursesw.so.5 /usr/lib/libncursesw.so"

    echo_cmd "for lib in curses ncurses form panel menu ; do
rm -vf /usr/lib/lib\${lib}.so ;
echo \"INPUT(-l\${lib}w)\" >/usr/lib/lib\${lib}.so ;
ln -sfv lib\${lib}w.a /usr/lib/lib\${lib}.a ;
done"
    for lib in curses ncurses form panel menu ; do
        eval_cmd "rm -vf /usr/lib/lib${lib}.so"
        eval_cmd "echo \"INPUT(-l${lib}w)\" >/usr/lib/lib${lib}.so"
        eval_cmd "ln -sfv lib${lib}w.a /usr/lib/lib${lib}.a"
    done

    cmd "ln -sfv libncurses++w.a /usr/lib/libncurses++.a"
    cmd "rm -vf /usr/lib/libcursesw.so"
    cmd "echo \"INPUT(-lncursesw)\" >/usr/lib/libcursesw.so"
    cmd "ln -sfv libncurses.so /usr/lib/libcurses.so"
    cmd "ln -sfv libncursesw.a /usr/lib/libcursesw.a"
    cmd "ln -sfv libncurses.a /usr/lib/libcurses.a"
    cmd "cd .."
    cmd "rm -rf ${PKG_WORKDIR}"
    place_marker "ncurses"
fi

if ! marker_exists "procps" ; then
    unpack_pkg ${PROCPS_PKG}
    get_patch_files ${PROCPS_PATCH0}
    cmd "cd ${PKG_WORKDIR}"
    cmd "patch -Np1 -i ../${PATCH_FILES[0]}"
    cmd "make"
    cmd "make install"
    cmd "cd .."
    cmd "rm -rf ${PKG_WORKDIR}"
    place_marker "procps"
fi

if ! marker_exists "libtool" ; then
    unpack_pkg ${LIBTOOL_PKG}
    cmd "cd ${PKG_WORKDIR}"
    cmd "./configure --prefix=/usr"
    cmd "make"
    cmd "make install"
    cmd "cd .."
    cmd "rm -rf ${PKG_WORKDIR}"
    place_marker "libtool"
fi

if ! marker_exists "zlib" ; then
    unpack_pkg ${ZLIB_PKG}
    cmd "cd ${PKG_WORKDIR}"
    cmd "./configure --prefix=/usr --shared --libdir=/lib"
    cmd "make"
    cmd "make install"
    cmd "rm -v /lib/libz.so"
    cmd "ln -sfv ../../lib/libz.so.1.2.3 /usr/lib/libz.so"
    cmd "make clean"
    cmd "./configure --prefix=/usr"
    cmd "make"
    cmd "make install"
    cmd "chmod -v 644 /usr/lib/libz.a"
    cmd "cd .."
    cmd "rm -rf ${PKG_WORKDIR}"
    place_marker "zlib"
fi

if ! marker_exists "perl" ; then
    unpack_pkg ${PERL_PKG}
    get_patch_files ${PERL_PATCH0}
    cmd "cd ${PKG_WORKDIR}"
    cmd "echo \"127.0.0.1 localhost \$(hostname)\" > /etc/hosts"
    cmd "patch -Np1 -i ../${PATCH_FILES[0]}"
    cmd 'sed -i -e "s|BUILD_ZLIB\s*= True|BUILD_ZLIB = False|"           \
       -e "s|INCLUDE\s*= ./zlib-src|INCLUDE    = /usr/include|" \
       -e "s|LIB\s*= ./zlib-src|LIB        = /usr/lib|"         \
    ext/Compress/Raw/Zlib/config.in'
    cmd "sh Configure -des -Dprefix=/usr \
                  -Dvendorprefix=/usr           \
                  -Dman1dir=/usr/share/man/man1 \
                  -Dman3dir=/usr/share/man/man3 \
                  -Dpager=\"/usr/bin/less -isR\""
    cmd "make"
    cmd "make install"
    cmd "cd .."
    cmd "rm -rf ${PKG_WORKDIR}"
    place_marker "perl"
fi

if ! marker_exists "readline" ; then
    unpack_pkg ${READLINE_PKG}
    get_patch_files ${READLINE_PATCH0}
    cmd "cd ${PKG_WORKDIR}"
    cmd "sed -i '/MV.*old/d' Makefile.in"
    cmd "sed -i '/{OLDSUFF}/c:' support/shlib-install"
    cmd "patch -Np1 -i ../${PATCH_FILES[0]}"
    cmd "./configure --prefix=/usr --libdir=/lib"
    cmd "make SHLIB_LIBS=-lncurses"
    cmd "make install"
    cmd "mv -v /lib/lib{readline,history}.a /usr/lib"
    cmd "rm -v /lib/lib{readline,history}.so"
    cmd "ln -sfv ../../lib/libreadline.so.5 /usr/lib/libreadline.so"
    cmd "ln -sfv ../../lib/libhistory.so.5 /usr/lib/libhistory.so"
    cmd "cd .."
    cmd "rm -rf ${PKG_WORKDIR}"
    place_marker "readline"
fi

if ! marker_exists "autoconf" ; then
    unpack_pkg ${AUTOCONF_PKG}
    cmd "cd ${PKG_WORKDIR}"
    cmd "./configure --prefix=/usr"
    cmd "make"
    cmd "make install"
    cmd "cd .."
    cmd "rm -rf ${PKG_WORKDIR}"
    place_marker "autoconf"
fi

if ! marker_exists "automake" ; then
    unpack_pkg ${AUTOMAKE_PKG}
    get_patch_files ${AUTOMAKE_PATCH0}
    cmd "cd ${PKG_WORKDIR}"
    cmd "patch -Np1 -i ../${PATCH_FILES[0]}"
    cmd "./configure --prefix=/usr --docdir=/usr/share/doc/automake-1.10.1"
    cmd "make"
    cmd "make install"
    cmd "cd .."
    cmd "rm -rf ${PKG_WORKDIR}"
    place_marker "automake"
fi

if ! marker_exists "bash" ; then
    unpack_pkg ${BASH_PKG}
    get_patch_files ${BASH_PATCH0}
    cmd "cd ${PKG_WORKDIR}"
    cmd "patch -Np1 -i ../${PATCH_FILES[0]}"
    cmd "./configure --prefix=/usr --bindir=/bin \\
    --without-bash-malloc --with-installed-readline ac_cv_func_working_mktime=yes"
    cmd "make"
    cmd "make install"
    cmd "cd .."
    cmd "rm -rf ${PKG_WORKDIR}"
    place_marker "bash"
fi

echo_cmd "exec /bin/bash --login +h"
exec /bin/bash --login +h "${PRIS_DIR}/pris-rebuild-d.sh"

remove_pid "pris-rebuild-c"

logout
exit 0
