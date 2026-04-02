#!/bin/bash
# pris-rebuild-c.sh - Third part of LFS build script, in chroot

source "/pris/pris-fns.sh"

# Override default prompt with chroot prompt
PROMPT_PREPEND='(lfs chroot) '
PROMPT='\033[31m>\033[0m'

if ! marker_exists "init-chroot" ; then
    cmd 'mkdir -pv /{boot,home,mnt,opt,srv}'
    cmd 'mkdir -pv /etc/{opt,sysconfig}'
    cmd 'mkdir -pv /lib/firmware'
    cmd 'mkdir -pv /media/{floppy,cdrom}'
    cmd 'mkdir -pv /usr/{,local/}{include,src}'
    cmd 'mkdir -pv /usr/lib/locale'
    cmd 'mkdir -pv /usr/local/{bin,lib,sbin}'
    cmd 'mkdir -pv /usr/{,local/}share/{color,dict,doc,info,locale,man}'
    cmd 'mkdir -pv /usr/{,local/}share/{misc,terminfo,zoneinfo}'
    cmd 'mkdir -pv /usr/{,local/}share/man/man{1..8}'
    cmd 'mkdir -pv /var/{cache,local,log,mail,opt,spool}'
    cmd 'mkdir -pv /var/lib/{color,misc,locate}'
    cmd 'ln -sfv /run /var/run'
    cmd 'ln -sfv /run/lock /var/lock'
    cmd 'install -dv -m 0750 /root'
    cmd 'install -dv -m 1777 /tmp /var/tmp'
    cmd 'ln -sv /proc/self/mounts /etc/mtab'
    cmd 'cat > /etc/hosts << EOF
127.0.0.1 localhost $(hostname)
::1 localhost
EOF'
    cmd "cat > /etc/passwd << \"EOF\"
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/dev/null:/usr/bin/false
daemon:x:6:6:Daemon User:/dev/null:/usr/bin/false
messagebus:x:18:18:D-Bus Message Daemon User:/run/dbus:/usr/bin/false
uuidd:x:80:80:UUID Generation Daemon User:/dev/null:/usr/bin/false
nobody:x:65534:65534:Unprivileged User:/dev/null:/usr/bin/false
EOF"
    cmd "cat > /etc/group << \"EOF\"
root:x:0:
bin:x:1:daemon
sys:x:2:
kmem:x:3:
tape:x:4:
tty:x:5:
daemon:x:6:
floppy:x:7:
disk:x:8:
lp:x:9:
dialout:x:10:
audio:x:11:
video:x:12:
utmp:x:13:
cdrom:x:15:
adm:x:16:
messagebus:x:18:
input:x:24:
mail:x:34:
kvm:x:61:
uuidd:x:80:
wheel:x:97:
users:x:999:
nogroup:x:65534:
EOF"
    cmd 'echo "tester:x:101:101::/home/tester:/bin/bash" >> /etc/passwd'
    cmd 'echo "tester:x:101:" >> /etc/group'
    cmd 'install -o tester -d /home/tester'
    cmd 'touch /var/log/{btmp,lastlog,faillog,wtmp}'
    cmd 'chgrp -v utmp /var/log/lastlog'
    cmd 'chmod -v 664 /var/log/lastlog'
    cmd 'chmod -v 600 /var/log/btmp'
    place_marker "init-chroot"
fi

cmd 'cd /sources'

if ! marker_exists "temp-gettext" ; then
    cmd 'tar -xf gettext-0.26.tar.xz'
    cmd 'cd gettext-0.26'
    cmd './configure --disable-shared'
    cmd 'make'
    cmd 'cp -v gettext-tools/src/{msgfmt,msgmerge,xgettext} /usr/bin'
    cmd 'cd /sources'
    cmd 'rm -rf gettext-0.26'
    place_marker "temp-gettext"
fi

if ! marker_exists "temp-bison" ; then
    cmd 'tar -xf bison-3.8.2.tar.xz'
    cmd 'cd bison-3.8.2'
    cmd './configure --prefix=/usr \
            --docdir=/usr/share/doc/bison-3.8.2'
    cmd 'make'
    cmd 'make install'
    cmd 'cd /sources'
    cmd 'rm -rf bison-3.8.2'
    place_marker "temp-bison"
fi

if ! marker_exists "temp-perl" ; then
    cmd 'tar -xf perl-5.42.0.tar.xz'
    cmd 'cd perl-5.42.0'
    cmd 'sh Configure -des \
             -D prefix=/usr \
             -D vendorprefix=/usr \
             -D useshrplib \
             -D privlib=/usr/lib/perl5/5.42/core_perl \
             -D archlib=/usr/lib/perl5/5.42/core_perl \
             -D sitelib=/usr/lib/perl5/5.42/site_perl \
             -D sitearch=/usr/lib/perl5/5.42/site_perl \
             -D vendorlib=/usr/lib/perl5/5.42/vendor_perl \
             -D vendorarch=/usr/lib/perl5/5.42/vendor_perl'
    cmd 'make'
    cmd 'make install'
    cmd 'cd /sources'
    cmd 'rm -rf perl-5.42.0'
    place_marker "temp-perl"
fi

if ! marker_exists "temp-python" ; then
    cmd 'tar -xf Python-3.13.7.tar.xz'
    cmd 'cd Python-3.13.7'
    cmd './configure --prefix=/usr \
            --enable-shared \
            --without-ensurepip \
            --without-static-libpython'
    cmd 'make'
    cmd 'make install'
    cmd 'cd /sources'
    cmd 'rm -rf Python-3.13.7'
    place_marker "temp-python"
fi

if ! marker_exists "temp-texinfo" ; then
    cmd 'tar -xf texinfo-7.2.tar.xz'
    cmd 'cd texinfo-7.2'
    cmd './configure --prefix=/usr'
    cmd 'make'
    cmd 'make install'
    cmd 'cd /sources'
    cmd 'rm -rf texinfo-7.2'
    place_marker "temp-texinfo"
fi

if ! marker_exists "temp-util-linux" ; then
    cmd 'tar -xf util-linux-2.41.1.tar.xz'
    cmd 'cd util-linux-2.41.1'
    cmd 'mkdir -pv /var/lib/hwclock'
    cmd './configure --libdir=/usr/lib     \
            --runstatedir=/run    \
            --disable-chfn-chsh   \
            --disable-login       \
            --disable-nologin     \
            --disable-su          \
            --disable-setpriv     \
            --disable-runuser     \
            --disable-pylibmount  \
            --disable-static      \
            --disable-liblastlog2 \
            --without-python      \
            ADJTIME_PATH=/var/lib/hwclock/adjtime \
            --docdir=/usr/share/doc/util-linux-2.41.1'
    cmd 'make'
    cmd 'make install'
    cmd 'cd /sources'
    cmd 'rm -rf util-linux-2.41.1'
    place_marker "temp-util-linux"
fi

if ! marker_exists "clean-temp-system" ; then
    cmd 'rm -rf /usr/share/{info,man,doc}/*'
    cmd 'find /usr/{lib,libexec} -name \*.la -delete'
    cmd 'rm -rf /tools'
    place_marker "clean-temp-system"
fi

if ! marker_exists "man-pages" ; then
    cmd 'tar -xf man-pages-6.15.tar.xz'
    cmd 'cd man-pages-6.15'
    cmd 'rm -v man3/crypt*'
    cmd 'make -R GIT=false prefix=/usr install'
    cmd 'cd /sources'
    cmd 'rm -rf man-pages-6.15'
    place_marker "man-pages"
fi

if ! marker_exists "iana-etc" ; then
    cmd 'tar -xf iana-etc-20250807.tar.gz'
    cmd 'cd iana-etc-20250807'
    cmd 'cp services protocols /etc'
    cmd 'cd /sources'
    cmd 'rm -rf iana-etc-20250807'
    place_marker "iana-etc"
fi

if ! marker_exists "glibc" ; then
    cmd 'tar -xf glibc-2.42.tar.xz'
    cmd 'cd glibc-2.42'
    cmd 'patch -Np1 -i ../glibc-2.42-fhs-1.patch'
    cmd "sed -e '/unistd.h/i #include <string.h>' \\
    -e '/libc_rwlock_init/c\\
  __libc_rwlock_define_initialized (, reset_lock);\\
  memcpy (&lock, &reset_lock, sizeof (lock));' \\
    -i stdlib/abort.c"
    cmd 'mkdir -v build'
    cmd 'cd       build'
    cmd 'echo "rootsbindir=/usr/sbin" > configparms'
    cmd '../configure --prefix=/usr                   \
             --disable-werror                \
             --disable-nscd                  \
             libc_cv_slibdir=/usr/lib        \
             --enable-stack-protector=strong \
             --enable-kernel=5.4'
    cmd 'make'
    cmd 'make check'
    cmd 'touch /etc/ld.so.conf'
    cmd "sed '/test-installation/s@\$(PERL)@echo not running@' -i ../Makefile"
    cmd 'make install'
    cmd "sed '/RTLDLIST=/s@/usr@@g' -i /usr/bin/ldd"
    cmd 'localedef -i C -f UTF-8 C.UTF-8'
    cmd 'localedef -i cs_CZ -f UTF-8 cs_CZ.UTF-8'
    cmd 'localedef -i de_DE -f ISO-8859-1 de_DE'
    cmd 'localedef -i de_DE@euro -f ISO-8859-15 de_DE@euro'
    cmd 'localedef -i de_DE -f UTF-8 de_DE.UTF-8'
    cmd 'localedef -i el_GR -f ISO-8859-7 el_GR'
    cmd 'localedef -i en_GB -f ISO-8859-1 en_GB'
    cmd 'localedef -i en_GB -f UTF-8 en_GB.UTF-8'
    cmd 'localedef -i en_HK -f ISO-8859-1 en_HK'
    cmd 'localedef -i en_PH -f ISO-8859-1 en_PH'
    cmd 'localedef -i en_US -f ISO-8859-1 en_US'
    cmd 'localedef -i en_US -f UTF-8 en_US.UTF-8'
    cmd 'localedef -i es_ES -f ISO-8859-15 es_ES@euro'
    cmd 'localedef -i es_MX -f ISO-8859-1 es_MX'
    cmd 'localedef -i fa_IR -f UTF-8 fa_IR'
    cmd 'localedef -i fr_FR -f ISO-8859-1 fr_FR'
    cmd 'localedef -i fr_FR@euro -f ISO-8859-15 fr_FR@euro'
    cmd 'localedef -i fr_FR -f UTF-8 fr_FR.UTF-8'
    cmd 'localedef -i is_IS -f ISO-8859-1 is_IS'
    cmd 'localedef -i is_IS -f UTF-8 is_IS.UTF-8'
    cmd 'localedef -i it_IT -f ISO-8859-1 it_IT'
    cmd 'localedef -i it_IT -f ISO-8859-15 it_IT@euro'
    cmd 'localedef -i it_IT -f UTF-8 it_IT.UTF-8'
    cmd 'localedef -i ja_JP -f EUC-JP ja_JP'
    cmd 'localedef -i ja_JP -f UTF-8 ja_JP.UTF-8'
    cmd 'localedef -i nl_NL@euro -f ISO-8859-15 nl_NL@euro'
    cmd 'localedef -i ru_RU -f KOI8-R ru_RU.KOI8-R'
    cmd 'localedef -i ru_RU -f UTF-8 ru_RU.UTF-8'
    cmd 'localedef -i se_NO -f UTF-8 se_NO.UTF-8'
    cmd 'localedef -i ta_IN -f UTF-8 ta_IN.UTF-8'
    cmd 'localedef -i tr_TR -f UTF-8 tr_TR.UTF-8'
    cmd 'localedef -i zh_CN -f GB18030 zh_CN.GB18030'
    cmd 'localedef -i zh_HK -f BIG5-HKSCS zh_HK.BIG5-HKSCS'
    cmd 'localedef -i zh_TW -f UTF-8 zh_TW.UTF-8'
    cmd "cat > /etc/nsswitch.conf << \"EOF\"
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
    cmd 'tar -xf ../../tzdata2025b.tar.gz'
    cmd 'ZONEINFO=/usr/share/zoneinfo'
    cmd 'mkdir -pv $ZONEINFO/{posix,right}'
    cmd 'for tz in etcetera southamerica northamerica europe africa antarctica  \
          asia australasia backward; do
    zic -L /dev/null   -d $ZONEINFO       ${tz}
    zic -L /dev/null   -d $ZONEINFO/posix ${tz}
    zic -L leapseconds -d $ZONEINFO/right ${tz}
done'
    cmd 'cp -v zone.tab zone1970.tab iso3166.tab $ZONEINFO'
    cmd 'zic -d $ZONEINFO -p America/New_York'
    cmd 'unset ZONEINFO tz'
    cmd 'ln -sfv /usr/share/zoneinfo/America/New_York /etc/localtime'
    cmd "cat > /etc/ld.so.conf << \"EOF\"
# Begin /etc/ld.so.conf
/usr/local/lib
/opt/lib

EOF"
    cmd "cat >> /etc/ld.so.conf << \"EOF\"
# Add an include directory
include /etc/ld.so.conf.d/*.conf

EOF"
    cmd 'mkdir -pv /etc/ld.so.conf.d'
    cmd 'cd /sources'
    cmd 'rm -rf glibc-2.42'
    place_marker "glibc"
fi

if ! marker_exists "zlib" ; then
    cmd 'tar -xf zlib-1.3.1.tar.gz'
    cmd 'cd zlib-1.3.1'
    cmd './configure --prefix=/usr'
    cmd 'make'
    cmd 'make install'
    cmd 'cd /sources'
    cmd 'rm -rf zlib-1.3.1'
    place_marker "zlib"
fi

if ! marker_exists "bzip2" ; then
    cmd 'tar xf bzip2-1.0.8.tar.gz '
    cmd 'cd bzip2-1.0.8'
    cmd 'patch -Np1 -i ../bzip2-1.0.8-install_docs-1.patch'
    cmd "sed -i 's@\(ln -s -f \)\$(PREFIX)/bin/@\1@' Makefile"
    cmd 'sed -i "s@(PREFIX)/man@(PREFIX)/share/man@g" Makefile'
    cmd 'make -f Makefile-libbz2_so'
    cmd 'make clean'
    cmd 'make'
    cmd 'make PREFIX=/usr install'
    cmd 'cp -av libbz2.so.* /usr/lib'
    cmd 'ln -sv libbz2.so.1.0.8 /usr/lib/libbz2.so'
    cmd 'cp -v bzip2-shared /usr/bin/bzip2'
    cmd 'for i in /usr/bin/{bzcat,bunzip2}; do
  ln -sfv bzip2 $i
done'
    cmd 'rm -fv /usr/lib/libbz2.a'
    cmd 'cd /sources'
    cmd 'rm -rf bzip2-1.0.8'
    place_marker "bzip2"
fi

if ! marker_exists "xz" ; then
    cmd 'tar -xf xz-5.8.1.tar.xz'
    cmd 'cd xz-5.8.1'
    cmd './configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/xz-5.8.1'
    cmd 'make'
    cmd 'make install'
    cmd 'cd /sources'
    cmd 'rm -rf xz-5.8.1'
    place_marker "xz"
fi

if ! marker_exists "lz4" ; then
    cmd 'tar -xf lz4-1.10.0.tar.gz'
    cmd 'cd lz4-1.10.0'
    cmd 'make BUILD_STATIC=no PREFIX=/usr'
    cmd 'make BUILD_STATIC=no PREFIX=/usr install'
    cmd 'cd /sources'
    cmd 'rm -rf lz4-1.10.0'
    place_marker "lz4"
fi

if ! marker_exists "zstd" ; then
    cmd 'tar -xf zstd-1.5.7.tar.gz'
    cmd 'cd zstd-1.5.7'
    cmd 'make prefix=/usr'
    cmd 'make prefix=/usr install'
    cmd 'rm -v /usr/lib/libzstd.a'
    cmd 'cd /sources'
    cmd 'rm -rf zstd-1.5.7'
    place_marker "zstd"
fi

if ! marker_exists "file" ; then
    cmd 'tar -xf file-5.46.tar.gz'
    cmd 'cd file-5.46'
    cmd './configure --prefix=/usr'
    cmd 'make'
    cmd 'make install'
    cmd 'cd /sources'
    cmd 'rm -rf file-5.46'
    place_marker "file"
fi

if ! marker_exists "readline" ; then
    cmd 'tar -xf readline-8.3.tar.gz'
    cmd 'cd readline-8.3'
    cmd "sed -i '/MV.*old/d' Makefile.in"
    cmd "sed -i '/{OLDSUFF}/c:' support/shlib-install"
    cmd "sed -i 's/-Wl,-rpath,[^ ]*//' support/shobj-conf"
    cmd './configure --prefix=/usr    \
            --disable-static \
            --with-curses    \
            --docdir=/usr/share/doc/readline-8.3'
    cmd 'make SHLIB_LIBS="-lncursesw"'
    cmd 'make install'
    cmd 'install -v -m644 doc/*.{ps,pdf,html,dvi} /usr/share/doc/readline-8.3'
    cmd 'cd /sources'
    cmd 'rm -rf readline-8.3'
    place_marker "readline"
fi

if ! marker_exists "m4" ; then
    cmd 'tar -xf m4-1.4.20.tar.xz'
    cmd 'cd m4-1.4.20'
    cmd './configure --prefix=/usr'
    cmd 'make'
    cmd 'make install'
    cmd 'cd /sources'
    cmd 'rm -rf m4-1.4.20'
    place_marker "m4"
fi

if ! marker_exists "bc" ; then
    cmd 'tar -xf bc-7.0.3.tar.xz'
    cmd 'cd bc-7.0.3'
    cmd "CC='gcc -std=c99' ./configure --prefix=/usr -G -O3 -r"
    cmd 'make'
    cmd 'make install'
    cmd 'cd /sources'
    cmd 'rm -rf bc-7.0.3'
    place_marker "bc"
fi

if ! marker_exists "flex" ; then
    cmd 'tar -xf flex-2.6.4.tar.gz'
    cmd 'cd flex-2.6.4'
    cmd './configure --prefix=/usr \
            --docdir=/usr/share/doc/flex-2.6.4 \
            --disable-static'
    cmd 'make'
    cmd 'make install'
    cmd 'ln -sv flex   /usr/bin/lex'
    cmd 'ln -sv flex.1 /usr/share/man/man1/lex.1'
    cmd 'cd /sources'
    cmd 'rm -rf flex-2.6.4'
    place_marker "flex"
fi

if ! marker_exists "tcl" ; then
    cmd 'tar -xf tcl8.6.16-src.tar.gz'
    cmd 'cd tcl8.6.16'
    cmd 'SRCDIR=$(pwd)'
    cmd 'cd unix'
    cmd './configure --prefix=/usr           \
            --mandir=/usr/share/man \
            --disable-rpath'
    cmd 'make'
    cmd 'sed -e "s|$SRCDIR/unix|/usr/lib|" \
    -e "s|$SRCDIR|/usr/include|"  \
    -i tclConfig.sh'
    cmd 'sed -e "s|$SRCDIR/unix/pkgs/tdbc1.1.10|/usr/lib/tdbc1.1.10|" \
    -e "s|$SRCDIR/pkgs/tdbc1.1.10/generic|/usr/include|"     \
    -e "s|$SRCDIR/pkgs/tdbc1.1.10/library|/usr/lib/tcl8.6|"  \
    -e "s|$SRCDIR/pkgs/tdbc1.1.10|/usr/include|"             \
    -i pkgs/tdbc1.1.10/tdbcConfig.sh'
    cmd 'sed -e "s|$SRCDIR/unix/pkgs/itcl4.3.2|/usr/lib/itcl4.3.2|" \
    -e "s|$SRCDIR/pkgs/itcl4.3.2/generic|/usr/include|"    \
    -e "s|$SRCDIR/pkgs/itcl4.3.2|/usr/include|"            \
    -i pkgs/itcl4.3.2/itclConfig.sh'
    cmd 'unset SRCDIR'
    cmd 'make install'
    cmd 'chmod 644 /usr/lib/libtclstub8.6.a'
    cmd 'chmod -v u+w /usr/lib/libtcl8.6.so'
    cmd 'make install-private-headers'
    cmd 'ln -sfv tclsh8.6 /usr/bin/tclsh'
    cmd 'mv /usr/share/man/man3/{Thread,Tcl_Thread}.3'
    cmd 'cd ..'
    cmd 'tar -xf ../tcl8.6.16-html.tar.gz --strip-components=1'
    cmd 'mkdir -v -p /usr/share/doc/tcl-8.6.16'
    cmd 'cp -v -r  ./html/* /usr/share/doc/tcl-8.6.16'
    cmd 'cd /sources'
    cmd 'rm -rf tcl8.6.16'
    place_marker "tcl"
fi

if ! marker_exists "expect" ; then
    cmd 'tar -xf expect5.45.4.tar.gz'
    cmd 'cd expect5.45.4'
    cmd "python3 -c 'from pty import spawn; spawn([\"echo\", \"ok\"])'"
    cmd 'patch -Np1 -i ../expect-5.45.4-gcc15-1.patch'
    cmd './configure --prefix=/usr           \
            --with-tcl=/usr/lib     \
            --enable-shared         \
            --disable-rpath         \
            --mandir=/usr/share/man \
            --with-tclinclude=/usr/include'
    cmd 'make'
    cmd 'make install'
    cmd 'ln -svf expect5.45.4/libexpect5.45.4.so /usr/lib'
    cmd 'cd /sources'
    cmd 'rm -rf expect5.45.4'
    place_marker "expect"
fi

if ! marker_exists "dejagnu" ; then
    cmd 'tar -xf dejagnu-1.6.3.tar.gz'
    cmd 'cd dejagnu-1.6.3'
    cmd 'mkdir -v build'
    cmd 'cd       build'
    cmd '../configure --prefix=/usr'
    cmd 'makeinfo --html --no-split -o doc/dejagnu.html ../doc/dejagnu.texi'
    cmd 'makeinfo --plaintext       -o doc/dejagnu.txt  ../doc/dejagnu.texi'
    cmd 'make install'
    cmd 'install -v -dm755  /usr/share/doc/dejagnu-1.6.3'
    cmd 'install -v -m644   doc/dejagnu.{html,txt} /usr/share/doc/dejagnu-1.6.3'
    cmd 'cd /sources'
    cmd 'rm -rf dejagnu-1.6.3'
    place_marker "dejagnu"
fi

if ! marker_exists "pkgconf" ; then
    cmd 'tar -xf pkgconf-2.5.1.tar.xz'
    cmd 'cd pkgconf-2.5.1'
    cmd './configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/pkgconf-2.5.1'
    cmd 'make'
    cmd 'make install'
    cmd 'ln -sv pkgconf   /usr/bin/pkg-config'
    cmd 'ln -sv pkgconf.1 /usr/share/man/man1/pkg-config.1'
    cmd 'cd /sources'
    cmd 'rm -rf pkgconf-2.5.1'
    place_marker "pkgconf"
fi

if ! marker_exists "binutils" ; then
    cmd 'tar -xf binutils-2.45.tar.xz'
    cmd 'cd binutils-2.45'
    cmd 'mkdir -v build'
    cmd 'cd       build'
    cmd '../configure --prefix=/usr       \
             --sysconfdir=/etc   \
             --enable-ld=default \
             --enable-plugins    \
             --enable-shared     \
             --disable-werror    \
             --enable-64-bit-bfd \
             --enable-new-dtags  \
             --with-system-zlib  \
             --enable-default-hash-style=gnu'
    cmd 'make tooldir=/usr'
    cmd 'make -k check RUNTESTFLAGS="-v"'
    cmd "grep '^FAIL:' \$(find -name '*.log')"
    cmd 'make tooldir=/usr install'
    cmd 'rm -rfv /usr/lib/lib{bfd,ctf,ctf-nobfd,gprofng,opcodes,sframe}.a \
        /usr/share/doc/gprofng/'
    cmd 'cd /sources'
    cmd 'rm -rf binutils-2.45'
    place_marker "binutils"
fi

if ! marker_exists "gmp" ; then
    cmd 'tar -xf gmp-6.3.0.tar.xz'
    cmd 'cd gmp-6.3.0'
    cmd "sed -i '/long long t1;/,+1s/()/(...)/' configure"
    cmd './configure --prefix=/usr    \
            --enable-cxx     \
            --disable-static \
            --docdir=/usr/share/doc/gmp-6.3.0'
    cmd 'make'
    cmd 'make html'
    cmd 'make check 2>&1 | tee gmp-check-log'
    cmd "awk '/# PASS:/{total+=\$3} ; END{print total}' gmp-check-log"
    cmd 'make install'
    cmd 'make install-html'
    cmd 'cd /sources'
    cmd 'rm -rf gmp-6.3.0'
    place_marker "gmp"
fi

if ! marker_exists "mpfr" ; then
    cmd 'tar -xf mpfr-4.2.2.tar.xz'
    cmd 'cd mpfr-4.2.2'
    cmd './configure --prefix=/usr        \
            --disable-static     \
            --enable-thread-safe \
            --docdir=/usr/share/doc/mpfr-4.2.2'
    cmd 'make'
    cmd 'make html'
    cmd 'make check'
    cmd 'make install'
    cmd 'make install-html'
    cmd 'cd /sources'
    cmd 'rm -rf mpfr-4.2.2'
    place_marker "mpfr"
fi

if ! marker_exists "mpc" ; then
    cmd 'tar -xf mpc-1.3.1.tar.gz'
    cmd 'cd mpc-1.3.1'
    cmd './configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/mpc-1.3.1'
    cmd 'make'
    cmd 'make html'
    cmd 'make install'
    cmd 'make install-html'
    cmd 'cd /sources'
    cmd 'rm -rf mpc-1.3.1'
    place_marker "mpc"
fi

if ! marker_exists "attr" ; then
    cmd 'tar -xf attr-2.5.2.tar.gz'
    cmd 'cd attr-2.5.2'
    cmd './configure --prefix=/usr     \
            --disable-static  \
            --sysconfdir=/etc \
            --docdir=/usr/share/doc/attr-2.5.2'
    cmd 'make'
    cmd 'make install'
    cmd 'cd /sources'
    cmd 'rm -rf attr-2.5.2'
    place_marker "attr"
fi

if ! marker_exists "acl" ; then
    cmd 'tar -xf acl-2.3.2.tar.xz'
    cmd 'cd acl-2.3.2'
    cmd './configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/acl-2.3.2'
    cmd 'make'
    cmd 'make install'
    cmd 'cd /sources'
    cmd 'rm -rf acl-2.3.2'
    place_marker "acl"
fi

if ! marker_exists "libcap" ; then
    cmd 'tar -xf libcap-2.76.tar.xz'
    cmd 'cd libcap-2.76'
    cmd "sed -i '/install -m.*STA/d' libcap/Makefile"
    cmd 'make prefix=/usr lib=lib'
    cmd 'make prefix=/usr lib=lib install'
    cmd 'cd /sources'
    cmd 'rm -rf libcap-2.76'
    place_marker "libcap"
fi

if ! marker_exists "libxcrypt" ; then
    cmd 'tar -xf libxcrypt-4.4.38.tar.xz'
    cmd 'cd libxcrypt-4.4.38'
    cmd './configure --prefix=/usr                \
            --enable-hashes=strong,glibc \
            --enable-obsolete-api=no     \
            --disable-static             \
            --disable-failure-tokens'
    cmd 'make'
    cmd 'make install'
    cmd 'cd /sources'
    cmd 'rm -rf libxcrypt-4.4.38'
    place_marker "libxcrypt"
fi

if ! marker_exists "shadow" ; then
    cmd 'tar -xf shadow-4.18.0.tar.xz'
    cmd 'cd shadow-4.18.0'
    cmd "sed -i 's/groups\$(EXEEXT) //' src/Makefile.in"
    cmd "find man -name Makefile.in -exec sed -i 's/groups\\.1 / /'   {} \\;"
    cmd "find man -name Makefile.in -exec sed -i 's/getspnam\\.3 / /' {} \\;"
    cmd "find man -name Makefile.in -exec sed -i 's/passwd\\.5 / /'   {} \\;"
    cmd "sed -e 's:#ENCRYPT_METHOD DES:ENCRYPT_METHOD YESCRYPT:' \\
    -e 's:/var/spool/mail:/var/mail:'                   \\
    -e '/PATH=/{s@/sbin:@@;s@/bin:@@}'                  \\
    -i etc/login.defs"
    cmd 'touch /usr/bin/passwd'
    cmd './configure --sysconfdir=/etc   \
            --disable-static    \
            --with-{b,yes}crypt \
            --without-libbsd    \
            --with-group-name-max-length=32'
    cmd 'make'
    cmd 'make exec_prefix=/usr install'
    cmd 'make -C man install-man'
    cmd 'pwconv'
    cmd 'grpconv'
    cmd 'mkdir -p /etc/default'
    cmd 'useradd -D --gid 999'
    cmd 'cd /sources'
    cmd 'rm -rf shadow-4.18.0'
    place_marker "shadow"
fi

if ! marker_exists "gcc" ; then
    cmd 'tar -xf gcc-15.2.0.tar.xz'
    cmd 'cd gcc-15.2.0'
    cmd "case \$(uname -m) in
  x86_64)
    sed -e '/m64=/s/lib64/lib/' \\
        -i.orig gcc/config/i386/t-linux64
  ;;
esac"
    cmd 'mkdir -v build'
    cmd 'cd       build'
    cmd '../configure --prefix=/usr            \
             LD=ld                    \
             --enable-languages=c,c++ \
             --enable-default-pie     \
             --enable-default-ssp     \
             --enable-host-pie        \
             --disable-multilib       \
             --disable-bootstrap      \
             --disable-fixincludes    \
             --with-system-zlib'
    cmd 'make'
    cmd 'ulimit -s -H unlimited'
    cmd "sed -e '/cpython/d' -i ../gcc/testsuite/gcc.dg/plugin/plugin.exp"
    cmd 'chown -R tester .'
    cmd "su tester -c \"PATH=\$PATH make -k -j\$(nproc) check RUNTESTFLAGS='-v'\""
    cmd '../contrib/test_summary | grep -A7 Summ'
    cmd 'make install'
    cmd 'chown -v -R root:root \
    /usr/lib/gcc/$(gcc -dumpmachine)/15.2.0/include{,-fixed}'
    cmd 'ln -svr /usr/bin/cpp /usr/lib'
    cmd 'ln -sv gcc.1 /usr/share/man/man1/cc.1'
    cmd 'ln -sfv ../../libexec/gcc/$(gcc -dumpmachine)/15.2.0/liblto_plugin.so \
        /usr/lib/bfd-plugins/'
    cmd "echo 'int main(){}' | cc -x c - -v -Wl,--verbose &> dummy.log"
    cmd "readelf -l a.out | grep ': /lib'"
    cmd "grep -E -o '/usr/lib.*/S?crt[1in].*succeeded' dummy.log"
    cmd "grep -B4 '^ /usr/include' dummy.log"
    cmd "grep 'SEARCH.*/usr/lib' dummy.log |sed 's|; |\n|g'"
    cmd 'grep "/lib.*/libc.so.6 " dummy.log'
    cmd 'grep found dummy.log'
    cmd 'rm -v a.out dummy.log'
    cmd 'mkdir -pv /usr/share/gdb/auto-load/usr/lib'
    cmd 'mv -v /usr/lib/*gdb.py /usr/share/gdb/auto-load/usr/lib'
    cmd 'cd /sources'
    cmd 'rm -rf gcc-15.2.0'
    place_marker "gcc"
fi

if ! marker_exists "ncurses" ; then
    cmd 'tar -xf ncurses-6.5-20250809.tgz'
    cmd 'cd ncurses-6.5-20250809'
    cmd './configure --prefix=/usr           \
            --mandir=/usr/share/man \
            --with-shared           \
            --without-debug         \
            --without-normal        \
            --with-cxx-shared       \
            --enable-pc-files       \
            --with-pkg-config-libdir=/usr/lib/pkgconfig'
    cmd 'make'
    cmd 'make DESTDIR=$PWD/dest install'
    cmd 'install -vm755 dest/usr/lib/libncursesw.so.6.5 /usr/lib'
    cmd 'rm -v  dest/usr/lib/libncursesw.so.6.5'
    cmd "sed -e 's/^#if.*XOPEN.*\$/#if 1/' \\
        -i dest/usr/include/curses.h"
    cmd 'cp -av dest/* /'
    cmd 'for lib in ncurses form panel menu ; do
    ln -sfv lib${lib}w.so /usr/lib/lib${lib}.so
    ln -sfv ${lib}w.pc    /usr/lib/pkgconfig/${lib}.pc
done'
    cmd 'ln -sfv libncursesw.so /usr/lib/libcurses.so'
    cmd 'cp -v -R doc -T /usr/share/doc/ncurses-6.5-20250809'
    cmd 'cd /sources'
    cmd 'rm -rf ncurses-6.5-20250809'
    place_marker "ncurses"
fi

if ! marker_exists "sed" ; then
    cmd 'tar -xf sed-4.9.tar.xz'
    cnd 'cd sed-4.9'
    cmd './configure --prefix=/usr'
    cmd 'make'
    cmd 'make html'
    cmd 'make install'
    cmd 'install -d -m755           /usr/share/doc/sed-4.9'
    cmd 'install -m644 doc/sed.html /usr/share/doc/sed-4.9'
    cmd 'cd /sources'
    cmd 'rm -rf sed-4.9'
    place_marker "sed"
fi

if ! marker_exists "psmisc" ; then
    cmd 'tar -xf psmisc-23.7.tar.xz'
    cnd 'cd psmisc-23.7'
    cmd './configure --prefix=/usr'
    cmd 'make'
    cmd 'make install'
    cmd 'cd /sources'
    cmd 'rm -rf psmisc-23.7'
    place_marker "psmisc"
fi

if ! marker_exists "gettext" ; then
    cmd 'tar -xf gettext-0.26.tar.xz'
    cnd 'cd gettext-0.26'
    cmd './configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/gettext-0.26'
    cmd 'make'
    cmd 'make install'
    cmd 'chmod -v 0755 /usr/lib/preloadable_libintl.so'
    cmd 'cd /sources'
    cmd 'rm -rf gettext-0.26'
    place_marker "gettext"
fi

if ! marker_exists "bison" ; then
    cmd 'tar -xf bison-3.8.2.tar.xz'
    cmd 'cd bison-3.8.2'
    cmd './configure --prefix=/usr --docdir=/usr/share/doc/bison-3.8.2'
    cmd 'make'
    cmd 'make install'
    cmd 'cd /sources'
    cmd 'rm -rf bison-3.8.2'
    place_marker "bison"
fi

if ! marker_exists "grep" ; then
    cmd 'tar -xf grep-3.12.tar.xz'
    cmd 'cd grep-3.12'
    cmd 'sed -i "s/echo/#echo/" src/egrep.sh'
    cmd './configure --prefix=/usr'
    cmd 'make'
    cmd 'make install'
    cmd 'cd /sources'
    cmd 'rm -rf grep-3.12'
    place_marker "grep"
fi

if ! marker_exists "bash" ; then
    cmd 'tar -xf bash-5.3.tar.gz'
    cmd 'cd bash-5.3'
    cmd './configure --prefix=/usr             \
            --without-bash-malloc     \
            --with-installed-readline \
            --docdir=/usr/share/doc/bash-5.3'
    cmd 'make'
    cmd 'make install'
    cmd 'cd /sources'
    cmd 'rm -rf bash-5.3'
    place_marker "bash"
fi

echo_cmd 'exec /usr/bin/bash --login'
exec /usr/bin/bash --login "${PRIS_DIR}/pris-rebuild-d.sh"

# Return back to pris-rebuild-a.
logout
