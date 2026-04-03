#!/bin/bash
# pris-rebuild-b.sh - Second part of LFS build script, as lfs user

source "/pris/pris-fns.sh"

# Override default prompt with user prompt
PROMPT='\033[1;35m>\033[0m'

export LFS=/mnt/lfs

if ! marker_exists "lfs-user-b" ; then

    # Make sure lfs env is virginal.
    if test -f "${LFS_HOME}/.bash_profile" ; then
        rm "${LFS_HOME}/.bash_profile"
    fi
    if test -f "${LFS_HOME}/.bashrc" ; then
        rm "${LFS_HOME}/.bashrc"
    fi

    # Don't actually save this .bash_profile for lfs, as the `exec` will
    # replace the rebuild script given to lfs to run.
    echo_prompt
    echo "cat > ~/.bash_profile << \"EOF\"
exec env -i HOME=\$HOME TERM=\$TERM PS1='[\h:\w]\\n\033[35m>\033[0m ' /bin/bash
EOF"

    cmd "cat > ~/.bashrc << \"EOF\"
set +h
umask 022
LFS=/mnt/lfs
LC_ALL=POSIX
LFS_TGT=\$(uname -m)-lfs-linux-gnu
PATH=/usr/bin
if [ ! -L /bin ]; then PATH=/bin:\$PATH; fi
PATH=\$LFS/tools/bin:\$PATH
CONFIG_SITE=\$LFS/usr/share/config.site
export LFS LC_ALL LFS_TGT PATH CONFIG_SITE
export MAKEFLAGS=-j\$(nproc)
EOF"

    place_marker "lfs-user-b"
fi

# Use this as the .bash_profile instead.
cat > /home/lfs/.bash_profile << "EOF"
export HOME=/home/lfs
export TERM=$TERM
export PS1='\u:\w\$ '
source ~/.bashrc
EOF

cmd 'source ~/.bash_profile'
cmd 'cd $LFS/sources'

if ! marker_exists "tools-binutils-pass1" ; then
    cmd 'tar -xf binutils-2.45.tar.xz'
    cmd 'cd binutils-2.45'
    cmd 'mkdir -v build'
    cmd 'cd       build'
    cmd '../configure --prefix=$LFS/tools \
             --with-sysroot=$LFS \
             --target=$LFS_TGT   \
             --disable-nls       \
             --enable-gprofng=no \
             --disable-werror    \
             --enable-new-dtags  \
             --enable-default-hash-style=gnu'
    cmd 'make'
    cmd 'make install'
    cmd 'cd $LFS/sources'
    cmd 'rm -rf binutils-2.45'
    place_marker "tools-binutils-pass1"
fi

if ! marker_exists "tools-gcc-pass1" ; then
    cmd 'tar -xf gcc-15.2.0.tar.xz'
    cmd 'cd gcc-15.2.0'
    cmd 'tar -xf ../mpfr-4.2.2.tar.xz'
    cmd 'mv -v mpfr-4.2.2 mpfr'
    cmd 'tar -xf ../gmp-6.3.0.tar.xz'
    cmd 'mv -v gmp-6.3.0 gmp'
    cmd 'tar -xf ../mpc-1.3.1.tar.gz'
    cmd 'mv -v mpc-1.3.1 mpc'
    cmd "case \$(uname -m) in
  x86_64)
    sed -e '/m64=/s/lib64/lib/' \
        -i.orig gcc/config/i386/t-linux64
 ;;
esac"
    cmd 'mkdir -v build'
    cmd 'cd       build'
    cmd '../configure                  \
    --target=$LFS_TGT         \
    --prefix=$LFS/tools       \
    --with-glibc-version=2.42 \
    --with-sysroot=$LFS       \
    --with-newlib             \
    --without-headers         \
    --enable-default-pie      \
    --enable-default-ssp      \
    --disable-nls             \
    --disable-shared          \
    --disable-multilib        \
    --disable-threads         \
    --disable-libatomic       \
    --disable-libgomp         \
    --disable-libquadmath     \
    --disable-libssp          \
    --disable-libvtv          \
    --disable-libstdcxx       \
    --enable-languages=c,c++'
    cmd 'make'
    cmd 'make install'
    cmd 'cd ..'
    cmd 'cat gcc/limitx.h gcc/glimits.h gcc/limity.h > \
  `dirname $($LFS_TGT-gcc -print-libgcc-file-name)`/include/limits.h'
    cmd 'cd $LFS/sources'
    cmd 'rm -rf gcc-15.2.0'
    place_marker "tools-gcc-pass1"
fi

if ! marker_exists "tools-linux-headers" ; then
    cmd 'tar -xf linux-6.16.1.tar.xz'
    cmd 'cd linux-6.16.1'
    cmd 'make mrproper'
    cmd 'make headers'
    cmd "find usr/include -type f ! -name '*.h' -delete"
    cmd 'cp -rv usr/include $LFS/usr'
    cmd 'cd $LFS/sources'
    cmd 'rm -rf linux-6.16.1'
    place_marker "tools-linux-headers"
fi

if ! marker_exists "tools-glibc" ; then
    cmd 'tar -xf glibc-2.42.tar.xz'
    cmd 'cd glibc-2.42'
    cmd 'case $(uname -m) in
    i?86)   ln -sfv ld-linux.so.2 $LFS/lib/ld-lsb.so.3
    ;;
    x86_64) ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS/lib64
            ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS/lib64/ld-lsb-x86-64.so.3
    ;;
esac'
    cmd 'patch -Np1 -i ../glibc-2.42-fhs-1.patch'
    cmd 'mkdir -v build'
    cmd 'cd       build'
    cmd 'echo "rootsbindir=/usr/sbin" > configparms'
    cmd '../configure                             \
      --prefix=/usr                      \
      --host=$LFS_TGT                    \
      --build=$(../scripts/config.guess) \
      --disable-nscd                     \
      libc_cv_slibdir=/usr/lib           \
      --enable-kernel=5.4'
    cmd 'make'
    cmd 'make DESTDIR=$LFS install'
    cmd "sed '/RTLDLIST=/s@/usr@@g' -i $LFS/usr/bin/ldd"
    cmd "echo 'int main(){}' | $LFS_TGT-gcc -x c - -v -Wl,--verbose &> dummy.log"
    cmd "readelf -l a.out | grep ': /lib'"
    cmd 'grep -E -o "$LFS/lib.*/S?crt[1in].*succeeded" dummy.log'
    cmd 'grep -B3 "^ $LFS/usr/include" dummy.log'
    cmd "grep 'SEARCH.*/usr/lib' dummy.log |sed 's|; |\n|g'"
    cmd 'grep "/lib.*/libc.so.6 " dummy.log'
    cmd 'grep found dummy.log'
    cmd 'rm -v a.out dummy.log'
    cmd 'cd $LFS/sources'
    cmd 'rm -rf glibc-2.42'
    place_marker "tools-glibc"
fi

if ! marker_exists "tools-libstdc++" ; then
    cmd 'tar -xf gcc-15.2.0.tar.xz'
    cmd 'cd gcc-15.2.0'
    cmd 'mkdir -v build'
    cmd 'cd       build'
    cmd '../libstdc++-v3/configure      \
    --host=$LFS_TGT            \
    --build=$(../config.guess) \
    --prefix=/usr              \
    --disable-multilib         \
    --disable-nls              \
    --disable-libstdcxx-pch    \
    --with-gxx-include-dir=/tools/$LFS_TGT/include/c++/15.2.0'
    cmd 'make'
    cmd 'make DESTDIR=$LFS install'
    cmd 'rm -v $LFS/usr/lib/lib{stdc++{,exp,fs},supc++}.la'
    cmd 'cd $LFS/sources'
    cmd 'rm -rf gcc-15.2.0'
    place_marker "tools-libstdc++"
fi

if ! marker_exists "tools-m4" ; then
    cmd 'tar -xf m4-1.4.20.tar.xz'
    cmd 'cd m4-1.4.20'
    cmd './configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)'
    cmd 'make'
    cmd 'make DESTDIR=$LFS install'
    cmd 'cd $LFS/sources'
    cmd 'rm -rf m4-1.4.20'
    place_marker "tools-m4"
fi

if ! marker_exists "tools-ncurses" ; then
    cmd 'tar -xf ncurses-6.5-20250809.tgz'
    cmd 'cd ncurses-6.5-20250809'
    cmd 'mkdir build'
    cmd 'pushd build
  ../configure --prefix=$LFS/tools AWK=gawk
  make -C include
  make -C progs tic
  install progs/tic $LFS/tools/bin
popd'
    cmd './configure --prefix=/usr                \
            --host=$LFS_TGT              \
            --build=$(./config.guess)    \
            --mandir=/usr/share/man      \
            --with-manpage-format=normal \
            --with-shared                \
            --without-normal             \
            --with-cxx-shared            \
            --without-debug              \
            --without-ada                \
            --disable-stripping          \
            AWK=gawk'
    cmd 'make'
    cmd 'make DESTDIR=$LFS install'
    cmd 'ln -sv libncursesw.so $LFS/usr/lib/libncurses.so'
    cmd "sed -e 's/^#if.*XOPEN.*$/#if 1/' \
    -i $LFS/usr/include/curses.h"
    cmd 'cd $LFS/sources'
    cmd 'rm -rf ncurses-6.5-20250809'
    place_marker "tools-ncurses"
fi

if ! marker_exists "tools-bash" ; then
    cmd 'tar -xf bash-5.3.tar.gz'
    cmd 'cd bash-5.3'
    cmd './configure --prefix=/usr                      \
            --build=$(sh support/config.guess) \
            --host=$LFS_TGT                    \
            --without-bash-malloc'
    cmd 'make'
    cmd 'make DESTDIR=$LFS install'
    cmd 'ln -sv bash $LFS/bin/sh'
    cmd 'cd $LFS/sources'
    cmd 'rm -rf bash-5.3'
    place_marker "tools-bash"
fi

if ! marker_exists "tools-coreutils" ; then
    cmd 'tar -xf coreutils-9.7.tar.xz'
    cmd 'cd coreutils-9.7'
    cmd './configure --prefix=/usr                     \
            --host=$LFS_TGT                   \
            --build=$(build-aux/config.guess) \
            --enable-install-program=hostname \
            --enable-no-install-program=kill,uptime'
    cmd 'make'
    cmd 'make DESTDIR=$LFS install'
    cmd 'mv -v $LFS/usr/bin/chroot              $LFS/usr/sbin'
    cmd 'mkdir -pv $LFS/usr/share/man/man8'
    cmd 'mv -v $LFS/usr/share/man/man1/chroot.1 $LFS/usr/share/man/man8/chroot.8'
    cmd 'sed -i 's/"1"/"8"/'                    $LFS/usr/share/man/man8/chroot.8'
    cmd 'cd $LFS/sources'
    cmd 'rm -rf coreutils-9.7'
    place_marker "tools-coreutils"
fi

if ! marker_exists "tools-diffutils" ; then
    cmd 'tar -xf diffutils-3.12.tar.xz '
    cmd 'cd diffutils-3.12'
    cmd './configure --prefix=/usr   \
            --host=$LFS_TGT \
            gl_cv_func_strcasecmp_works=y \
            --build=$(./build-aux/config.guess)'
    cmd 'make'
    cmd 'make DESTDIR=$LFS install'
    cmd 'cd $LFS/sources'
    cmd 'rm -rf diffutils-3.12'
    place_marker "tools-diffutils"
fi

if ! marker_exists "tools-file" ; then
    cmd 'tar -xf file-5.46.tar.gz'
    cmd 'cd file-5.46'
    cmd 'mkdir build'
    cmd 'pushd build
  ../configure --disable-bzlib      \
               --disable-libseccomp \
               --disable-xzlib      \
               --disable-zlib
  make
popd'
    cmd './configure --prefix=/usr --host=$LFS_TGT --build=$(./config.guess)'
    cmd 'make FILE_COMPILE=$(pwd)/build/src/file'
    cmd 'make DESTDIR=$LFS install'
    cmd 'rm -v $LFS/usr/lib/libmagic.la'
    cmd 'cd $LFS/sources'
    cmd 'rm -rf file-5.46'
    place_marker "tools-file"
fi

if ! marker_exists "tools-findutils" ; then
    cmd 'tar -xf findutils-4.10.0.tar.xz'
    cmd 'cd findutils-4.10.0'
    cmd './configure --prefix=/usr                   \
            --localstatedir=/var/lib/locate \
            --host=$LFS_TGT                 \
            --build=$(build-aux/config.guess)'
    cmd 'make'
    cmd 'make DESTDIR=$LFS install'
    cmd 'cd $LFS/sources'
    cmd 'rm -rf findutils-4.10.0'
    place_marker "tools-findutils"
fi

if ! marker_exists "tools-gawk" ; then
    cmd 'tar -xf gawk-5.3.2.tar.xz'
    cmd 'cd gawk-5.3.2'
    cmd "sed -i 's/extras//' Makefile.in"
    cmd './configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)'
    cmd 'make'
    cmd 'make DESTDIR=$LFS install'
    cmd 'cd $LFS/sources'
    cmd 'rm -rf gawk-5.3.2'
    place_marker "tools-gawk"
fi

if ! marker_exists "tools-grep" ; then
    cmd 'tar -xf grep-3.12.tar.xz '
    cmd 'cd grep-3.12'
    cmd './configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(./build-aux/config.guess)'
    cmd 'make'
    cmd 'make DESTDIR=$LFS install'
    cmd 'cd $LFS/sources'
    cmd 'rm -rf grep-3.12'
    place_marker "tools-grep"
fi

if ! marker_exists "tools-gzip" ; then
    cmd 'tar -xf gzip-1.14.tar.xz'
    cmd 'cd gzip-1.14'
    cmd './configure --prefix=/usr --host=$LFS_TGT'
    cmd 'make'
    cmd 'make DESTDIR=$LFS install'
    cmd 'cd $LFS/sources'
    cmd 'rm -rf gzip-1.14'
    place_marker "tools-gzip"
fi

if ! marker_exists "tools-make" ; then
    cmd 'tar -xf make-4.4.1.tar.gz'
    cmd 'cd make-4.4.1'
    cmd './configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)'
    cmd 'make'
    cmd 'make DESTDIR=$LFS install'
    cmd 'cd $LFS/sources'
    cmd 'rm -rf make-4.4.1'
    place_marker "tools-make"
fi

if ! marker_exists "tools-patch" ; then
    cmd 'tar -xf patch-2.8.tar.xz'
    cmd 'cd patch-2.8'
    cmd './configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)'
    cmd 'make'
    cmd 'make DESTDIR=$LFS install'
    cmd 'cd $LFS/sources'
    cmd 'rm -rf patch-2.8'
    place_marker "tools-patch"
fi

if ! marker_exists "tools-sed" ; then
    cmd 'tar -xf sed-4.9.tar.xz'
    cmd 'cd sed-4.9'
    cmd './configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(./build-aux/config.guess)'
    cmd 'make'
    cmd 'make DESTDIR=$LFS install'
    cmd 'cd $LFS/sources'
    cmd 'rm -rf sed-4.9'
    place_marker "tools-sed"
fi

if ! marker_exists "tools-tar" ; then
    cmd 'tar -xf tar-1.35.tar.xz'
    cmd 'cd tar-1.35'
    cmd './configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)'
    cmd 'make'
    cmd 'make DESTDIR=$LFS install'
    cmd 'cd $LFS/sources'
    cmd 'rm -rf tar-1.35'
    place_marker "tools-tar"
fi

if ! marker_exists "tools-xz" ; then
    cmd 'tar -xf xz-5.8.1.tar.xz'
    cmd 'cd xz-5.8.1'
    cmd './configure --prefix=/usr                     \
            --host=$LFS_TGT                   \
            --build=$(build-aux/config.guess) \
            --disable-static                  \
            --docdir=/usr/share/doc/xz-5.8.1'
    cmd 'make'
    cmd 'make DESTDIR=$LFS install'
    cmd 'rm -v $LFS/usr/lib/liblzma.la'
    cmd 'cd $LFS/sources'
    cmd 'rm -rf xz-5.8.1'
    place_marker "tools-xz"
fi

if ! marker_exists "tools-binutils-pass2" ; then
    cmd 'tar -xf binutils-2.45.tar.xz'
    cmd 'cd binutils-2.45'
    cmd "sed '6031s/\$add_dir//' -i ltmain.sh"
    cmd 'mkdir -v build'
    cmd 'cd       build'
    cmd '../configure                   \
    --prefix=/usr              \
    --build=$(../config.guess) \
    --host=$LFS_TGT            \
    --disable-nls              \
    --enable-shared            \
    --enable-gprofng=no        \
    --disable-werror           \
    --enable-64-bit-bfd        \
    --enable-new-dtags         \
    --enable-default-hash-style=gnu'
    cmd 'make'
    cmd 'make DESTDIR=$LFS install'
    cmd 'rm -v $LFS/usr/lib/lib{bfd,ctf,ctf-nobfd,opcodes,sframe}.{a,la}'
    cmd 'cd $LFS/sources'
    cmd 'rm -rf binutils-2.45'
    place_marker "tools-binutils-pass2"
fi

if ! marker_exists "tools-gcc-pass2" ; then
    cmd 'tar -xf gcc-15.2.0.tar.xz'
    cmd 'cd gcc-15.2.0'
    cmd 'tar -xf ../mpfr-4.2.2.tar.xz'
    cmd 'mv -v mpfr-4.2.2 mpfr'
    cmd 'tar -xf ../gmp-6.3.0.tar.xz'
    cmd 'mv -v gmp-6.3.0 gmp'
    cmd 'tar -xf ../mpc-1.3.1.tar.gz'
    cmd 'mv -v mpc-1.3.1 mpc'
    cmd "case \$(uname -m) in
  x86_64)
    sed -e '/m64=/s/lib64/lib/' \
        -i.orig gcc/config/i386/t-linux64
  ;;
esac"
    cmd "sed '/thread_header =/s/@.*@/gthr-posix.h/' \
    -i libgcc/Makefile.in libstdc++-v3/include/Makefile.in"
    cmd 'mkdir -v build'
    cmd 'cd       build'
    cmd '../configure                   \
    --build=$(../config.guess) \
    --host=$LFS_TGT            \
    --target=$LFS_TGT          \
    --prefix=/usr              \
    --with-build-sysroot=$LFS  \
    --enable-default-pie       \
    --enable-default-ssp       \
    --disable-nls              \
    --disable-multilib         \
    --disable-libatomic        \
    --disable-libgomp          \
    --disable-libquadmath      \
    --disable-libsanitizer     \
    --disable-libssp           \
    --disable-libvtv           \
    --enable-languages=c,c++   \
    LDFLAGS_FOR_TARGET=-L$PWD/$LFS_TGT/libgcc'
    cmd 'make'
    cmd 'make DESTDIR=$LFS install'
    cmd 'ln -sv gcc $LFS/usr/bin/cc'
    cmd 'cd $LFS/sources'
    cmd 'rm -rf gcc-15.2.0'
    place_marker "tools-gcc-pass2"
fi

cmd 'exit'
