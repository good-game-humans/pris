#!/bin/bash
# pris-rebuild-d.sh - Fourth part of LFS build script, continuing build

source "/pris/pris-fns.sh"

# Override default prompt with chroot prompt
PROMPT_PREPEND='(lfs chroot) '
PROMPT='\033[1;31m>\033[0m'

if ! marker_exists "libtool" ; then
    cmd 'tar -xf libtool-2.5.4.tar.xz'
    cmd 'cd libtool-2.5.4'
    cmd './configure --prefix=/usr'
    cmd 'make'
    cmd 'make install'
    cmd 'rm -fv /usr/lib/libltdl.a'
    cmd 'cd /sources'
    cmd 'rm -rf libtool-2.5.4'
    place_marker "libtool"
fi

if ! marker_exists "gdbm" ; then
    cmd 'tar -xf gdbm-1.26.tar.gz'
    cmd 'cd gdbm-1.26'
    cmd './configure --prefix=/usr    \
            --disable-static \
            --enable-libgdbm-compat'
    cmd 'make'
    cmd 'make install'
    cmd 'cd /sources'
    cmd 'rm -rf gdbm-1.26'
    place_marker "gdbm"
fi

if ! marker_exists "gperf" ; then
    cmd 'tar -xf gperf-3.3.tar.gz'
    cmd 'cd gperf-3.3'
    cmd './configure --prefix=/usr --docdir=/usr/share/doc/gperf-3.3'
    cmd 'make'
    cmd 'make install'
    cmd 'cd /sources'
    cmd 'rm -rf gperf-3.3'
    place_marker "gperf"
fi

if ! marker_exists "expat" ; then
    cmd 'tar -xf expat-2.7.1.tar.xz'
    cmd 'cd expat-2.7.1'
    cmd './configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/expat-2.7.1'
    cmd 'make'
    cmd 'make install'
    cmd 'install -v -m644 doc/*.{html,css} /usr/share/doc/expat-2.7.1'
    cmd 'cd /sources'
    cmd 'rm -rf expat-2.7.1'
    place_marker "expat"
fi

if ! marker_exists "inetutils" ; then
    cmd 'tar -xf inetutils-2.6.tar.xz'
    cmd 'cd inetutils-2.6'
    cmd "sed -i 's/def HAVE_TERMCAP_TGETENT/ 1/' telnet/telnet.c"
    cmd './configure --prefix=/usr        \
            --bindir=/usr/bin    \
            --localstatedir=/var \
            --disable-logger     \
            --disable-whois      \
            --disable-rcp        \
            --disable-rexec      \
            --disable-rlogin     \
            --disable-rsh        \
            --disable-servers'
    cmd 'make'
    cmd 'make install'
    cmd 'mv -v /usr/{,s}bin/ifconfig'
    cmd 'cd /sources'
    cmd 'rm -rf inetutils-2.6'
    place_marker "inetutils"
fi

if ! marker_exists "less" ; then
    cmd 'tar -xf less-679.tar.gz'
    cmd 'cd less-679'
    cmd './configure --prefix=/usr --sysconfdir=/etc'
    cmd 'make'
    cmd 'make install'
    cmd 'cd /sources'
    cmd 'rm -rf less-679'
    place_marker "less"
fi

if ! marker_exists "perl" ; then
    cmd 'tar -xf perl-5.42.0.tar.xz'
    cmd 'cd perl-5.42.0'
    cmd 'export BUILD_ZLIB=False'
    cmd 'export BUILD_BZIP2=0'
    cmd 'sh Configure -des                                          \
             -D prefix=/usr                                \
             -D vendorprefix=/usr                          \
             -D privlib=/usr/lib/perl5/5.42/core_perl      \
             -D archlib=/usr/lib/perl5/5.42/core_perl      \
             -D sitelib=/usr/lib/perl5/5.42/site_perl      \
             -D sitearch=/usr/lib/perl5/5.42/site_perl     \
             -D vendorlib=/usr/lib/perl5/5.42/vendor_perl  \
             -D vendorarch=/usr/lib/perl5/5.42/vendor_perl \
             -D man1dir=/usr/share/man/man1                \
             -D man3dir=/usr/share/man/man3                \
             -D pager="/usr/bin/less -isR"                 \
             -D useshrplib                                 \
             -D usethreads'
    cmd 'make'
    cmd 'make install'
    cmd 'unset BUILD_ZLIB BUILD_BZIP2'
    cmd 'cd /sources'
    cmd 'rm -rf perl-5.42.0'
    place_marker "perl"
fi

if ! marker_exists "xml-parser" ; then
    cmd 'tar -xf XML-Parser-2.47.tar.gz'
    cmd 'cd XML-Parser-2.47'
    cmd 'perl Makefile.PL'
    cmd 'make'
    cmd 'make install'
    cmd 'cd /sources'
    cmd 'rm -rf XML-Parser-2.47'
    place_marker "xml-parser"
fi

if ! marker_exists "intltool" ; then
    cmd 'tar -xf intltool-0.51.0.tar.gz'
    cmd 'cd intltool-0.51.0'
    echo_prompt
    echo sed -i 's:\\\${:\\\$\\{:' intltool-update.in
    sed -i.orig 's:\\\${:\\\$\\{:' intltool-update.in
    cmd './configure --prefix=/usr'
    cmd 'make'
    cmd 'make install'
    cmd 'install -v -Dm644 doc/I18N-HOWTO /usr/share/doc/intltool-0.51.0/I18N-HOWTO'
    cmd 'cd /sources'
    cmd 'rm -rf intltool-0.51.0'
    place_marker "intltool"
fi

if ! marker_exists "autoconf" ; then
    cmd 'tar -xf autoconf-2.72.tar.xz'
    cmd 'cd autoconf-2.72'
    cmd './configure --prefix=/usr'
    cmd 'make'
    cmd 'make install'
    cmd 'cd /sources'
    cmd 'rm -rf autoconf-2.72'
    place_marker "autoconf"
fi

if ! marker_exists "automake" ; then
    cmd 'tar -xf automake-1.18.1.tar.xz'
    cmd 'cd automake-1.18.1'
    cmd './configure --prefix=/usr --docdir=/usr/share/doc/automake-1.18.1'
    cmd 'make'
    cmd 'make install'
    cmd 'cd /sources'
    cmd 'rm -rf automake-1.18.1'
    place_marker "automake"
fi

if ! marker_exists "openssl" ; then
    cmd 'tar -xf openssl-3.5.2.tar.gz'
    cmd 'cd openssl-3.5.2'
    cmd './config --prefix=/usr         \
         --openssldir=/etc/ssl \
         --libdir=lib          \
         shared                \
         zlib-dynamic'
    cmd 'make'
    cmd "sed -i '/INSTALL_LIBS/s/libcrypto.a libssl.a//' Makefile"
    cmd 'make MANSUFFIX=ssl install'
    cmd 'mv -v /usr/share/doc/openssl /usr/share/doc/openssl-3.5.2'
    cmd 'cp -vfr doc/* /usr/share/doc/openssl-3.5.2'
    cmd 'cd /sources'
    cmd 'rm -rf openssl-3.5.2'
    place_marker "openssl"
fi

if ! marker_exists "libelf" ; then
    cmd 'tar -xf elfutils-0.193.tar.bz2'
    cmd 'cd elfutils-0.193'
    cmd './configure --prefix=/usr        \
            --disable-debuginfod \
            --enable-libdebuginfod=dummy'
    cmd 'make'
    cmd 'make -C libelf install'
    cmd 'install -vm644 config/libelf.pc /usr/lib/pkgconfig'
    cmd 'rm /usr/lib/libelf.a'
    cmd 'cd /sources'
    cmd 'rm -rf elfutils-0.193'
    place_marker "libelf"
fi

if ! marker_exists "libffi" ; then
    cmd 'tar -xf libffi-3.5.2.tar.gz'
    cmd 'cd libffi-3.5.2'
    cmd './configure --prefix=/usr    \
            --disable-static \
            --with-gcc-arch=native'
    cmd 'make'
    cmd 'make install'
    cmd 'cd /sources'
    cmd 'rm -rf libffi-3.5.2'
    place_marker "libffi"
fi

if ! marker_exists "python" ; then
    cmd 'tar -xf Python-3.13.7.tar.xz'
    cmd 'cd Python-3.13.7'
    cmd './configure --prefix=/usr          \
            --enable-shared        \
            --with-system-expat    \
            --enable-optimizations \
            --without-static-libpython'
    cmd 'make'
    cmd 'make install'
    cmd 'install -v -dm755 /usr/share/doc/python-3.13.7/html'
    cmd 'tar --strip-components=1  \
    --no-same-owner       \
    --no-same-permissions \
    -C /usr/share/doc/python-3.13.7/html \
    -xvf ../python-3.13.7-docs-html.tar.bz2'
    cmd 'cd /sources'
    cmd 'rm -rf Python-3.13.7'
    place_marker "python"
fi

if ! marker_exists "flit-core" ; then
    cmd 'tar -xf flit_core-3.12.0.tar.gz'
    cmd 'cd flit_core-3.12.0'
    cmd 'pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD'
    cmd 'pip3 install --no-index --find-links dist flit_core'
    cmd 'cd /sources'
    cmd 'rm -rf flit_core-3.12.0'
    place_marker "flit-core"
fi

if ! marker_exists "packaging" ; then
    cmd 'tar -xf packaging-25.0.tar.gz'
    cmd 'cd packaging-25.0'
    cmd 'pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD'
    cmd 'pip3 install --no-index --find-links dist packaging'
    cmd 'cd /sources'
    cmd 'rm -rf packaging-25.0'
    place_marker "packaging"
fi

if ! marker_exists "wheel" ; then
    cmd 'tar -xf wheel-0.46.1.tar.gz'
    cmd 'cd wheel-0.46.1'
    cmd 'pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD'
    cmd 'pip3 install --no-index --find-links dist wheel'
    cmd 'cd /sources'
    cmd 'rm -rf wheel-0.46.1'
    place_marker "wheel"
fi

if ! marker_exists "setuptools" ; then
    cmd 'tar -xf setuptools-80.9.0.tar.gz'
    cmd 'cd setuptools-80.9.0'
    cmd 'pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD'
    cmd 'pip3 install --no-index --find-links dist setuptools'
    cmd 'cd /sources'
    cmd 'rm -rf setuptools-80.9.0'
    place_marker "setuptools"
fi

if ! marker_exists "ninja" ; then
    cmd 'tar -xf ninja-1.13.1.tar.gz'
    cmd 'cd ninja-1.13.1'
    cmd 'export NINJAJOBS=$(nproc)'
    cmd 'sed -i '"'"'/int Guess/a \
  int   j = 0;\
  char* jobs = getenv( "NINJAJOBS" );\
  if ( jobs != NULL ) j = atoi( jobs );\
  if ( j > 0 ) return j;\
'"'"' src/ninja.cc'
    cmd 'python3 configure.py --bootstrap --verbose'
    cmd 'install -vm755 ninja /usr/bin/'
    cmd 'install -vDm644 misc/bash-completion /usr/share/bash-completion/completions/ninja'
    cmd 'install -vDm644 misc/zsh-completion  /usr/share/zsh/site-functions/_ninja'
    cmd 'cd /sources'
    cmd 'rm -rf ninja-1.13.1'
    place_marker "ninja"
fi

export NINJAJOBS=$(nproc)

if ! marker_exists "meson" ; then
    cmd 'tar -xf meson-1.8.3.tar.gz'
    cmd 'cd meson-1.8.3'
    cmd 'pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD'
    cmd 'pip3 install --no-index --find-links dist meson'
    cmd 'install -vDm644 data/shell-completions/bash/meson /usr/share/bash-completion/completions/meson'
    cmd 'install -vDm644 data/shell-completions/zsh/_meson /usr/share/zsh/site-functions/_meson'
    cmd 'cd /sources'
    cmd 'rm -rf meson-1.8.3'
    place_marker "meson"
fi

if ! marker_exists "kmod" ; then
    cmd 'tar -xf kmod-34.2.tar.xz'
    cmd 'cd kmod-34.2'
    cmd 'mkdir -p build'
    cmd 'cd       build'
    cmd 'meson setup --prefix=/usr ..    \
            --buildtype=release \
            -D manpages=false'
    cmd 'ninja'
    cmd 'ninja install'
    cmd 'cd /sources'
    cmd 'rm -rf kmod-34.2'
    place_marker "kmod"
fi

if ! marker_exists "coreutils" ; then
    cmd 'tar -xf coreutils-9.7.tar.xz'
    cmd 'cd coreutils-9.7'
    cmd 'patch -Np1 -i ../coreutils-9.7-upstream_fix-1.patch'
    cmd 'patch -Np1 -i ../coreutils-9.7-i18n-1.patch'
    cmd 'autoreconf -fv'
    cmd 'automake -af'
    cmd 'FORCE_UNSAFE_CONFIGURE=1 ./configure \
            --prefix=/usr            \
            --enable-no-install-program=kill,uptime'
    cmd 'make'
    cmd 'make install'
    cmd 'mv -v /usr/bin/chroot /usr/sbin'
    cmd 'mv -v /usr/share/man/man1/chroot.1 /usr/share/man/man8/chroot.8'
    cmd "sed -i 's/\"1\"/\"8\"/' /usr/share/man/man8/chroot.8"
    cmd 'cd /sources'
    cmd 'rm -rf coreutils-9.7'
    place_marker "coreutils"
fi

if ! marker_exists "diffutils" ; then
    cmd 'tar -xf diffutils-3.12.tar.xz'
    cmd 'cd diffutils-3.12'
    cmd './configure --prefix=/usr'
    cmd 'make'
    cmd 'make install'
    cmd 'cd /sources'
    cmd 'rm -rf diffutils-3.12'
    place_marker "diffutils"
fi

if ! marker_exists "gawk" ; then
    cmd 'tar -xf gawk-5.3.2.tar.xz'
    cmd 'cd gawk-5.3.2'
    cmd "sed -i 's/extras//' Makefile.in"
    cmd './configure --prefix=/usr'
    cmd 'make'
    cmd 'rm -f /usr/bin/gawk-5.3.2'
    cmd 'make install'
    cmd 'ln -sv gawk.1 /usr/share/man/man1/awk.1'
    cmd 'install -vDm644 doc/{awkforai.txt,*.{eps,pdf,jpg}} -t /usr/share/doc/gawk-5.3.2'
    cmd 'cd /sources'
    cmd 'rm -rf gawk-5.3.2'
    place_marker "gawk"
fi

if ! marker_exists "findutils" ; then
    cmd 'tar -xf findutils-4.10.0.tar.xz'
    cmd 'cd findutils-4.10.0'
    cmd './configure --prefix=/usr --localstatedir=/var/lib/locate'
    cmd 'make'
    cmd 'make install'
    cmd 'cd /sources'
    cmd 'rm -rf findutils-4.10.0'
    place_marker "findutils"
fi

if ! marker_exists "groff" ; then
    cmd 'tar -xf groff-1.23.0.tar.gz'
    cmd 'cd groff-1.23.0'
    cmd 'PAGE=letter ./configure --prefix=/usr'
    cmd 'make'
    cmd 'make install'
    cmd 'cd /sources'
    cmd 'rm -rf groff-1.23.0'
    place_marker "groff"
fi

if ! marker_exists "grub" ; then
    cmd 'tar -xf grub-2.12.tar.xz'
    cmd 'cd grub-2.12'
    cmd 'unset {C,CPP,CXX,LD}FLAGS'
    cmd 'echo depends bli part_gpt > grub-core/extra_deps.lst'
    cmd './configure --prefix=/usr     \
            --sysconfdir=/etc \
            --disable-efiemu  \
            --disable-werror'
    cmd 'make'
    cmd 'make install'
    cmd 'mv -v /etc/bash_completion.d/grub /usr/share/bash-completion/completions'
    cmd 'cd /sources'
    cmd 'rm -rf grub-2.12'
    place_marker "grub"
fi

if ! marker_exists "gzip" ; then
    cmd 'tar -xf gzip-1.14.tar.xz'
    cmd 'cd gzip-1.14'
    cmd './configure --prefix=/usr'
    cmd 'make'
    cmd 'make install'
    cmd 'cd /sources'
    cmd 'rm -rf gzip-1.14'
    place_marker "gzip"
fi

if ! marker_exists "iproute2" ; then
    cmd 'tar -xf iproute2-6.16.0.tar.xz'
    cmd 'cd iproute2-6.16.0'
    cmd 'sed -i /ARPD/d Makefile'
    cmd 'rm -fv man/man8/arpd.8'
    cmd 'make NETNS_RUN_DIR=/run/netns'
    cmd 'make SBINDIR=/usr/sbin install'
    cmd 'install -vDm644 COPYING README* -t /usr/share/doc/iproute2-6.16.0'
    cmd 'cd /sources'
    cmd 'rm -rf iproute2-6.16.0'
    place_marker "iproute2"
fi

if ! marker_exists "kbd" ; then
    cmd 'tar -xf kbd-2.8.0.tar.xz'
    cmd 'cd kbd-2.8.0'
    cmd 'patch -Np1 -i ../kbd-2.8.0-backspace-1.patch'
    cmd "sed -i '/RESIZECONS_PROGS=/s/yes/no/' configure"
    cmd "sed -i 's/resizecons.8 //' docs/man/man8/Makefile.in"
    cmd './configure --prefix=/usr --disable-vlock'
    cmd 'make'
    cmd 'make install'
    cmd 'cp -R -v docs/doc -T /usr/share/doc/kbd-2.8.0'
    cmd 'cd /sources'
    cmd 'rm -rf kbd-2.8.0'
    place_marker "kbd"
fi

if ! marker_exists "libpipeline" ; then
    cmd 'tar -xf libpipeline-1.5.8.tar.gz'
    cmd 'cd libpipeline-1.5.8'
    cmd './configure --prefix=/usr'
    cmd 'make'
    cmd 'make install'
    cmd 'cd /sources'
    cmd 'rm -rf libpipeline-1.5.8'
    place_marker "libpipeline"
fi

if ! marker_exists "make" ; then
    cmd 'tar -xf make-4.4.1.tar.gz'
    cmd 'cd make-4.4.1'
    cmd './configure --prefix=/usr'
    cmd 'make'
    cmd 'make install'
    cmd 'cd /sources'
    cmd 'rm -rf make-4.4.1'
    place_marker "make"
fi

if ! marker_exists "patch" ; then
    cmd 'tar -xf patch-2.8.tar.xz'
    cmd 'cd patch-2.8'
    cmd './configure --prefix=/usr'
    cmd 'make'
    cmd 'make install'
    cmd 'cd /sources'
    cmd 'rm -rf patch-2.8'
    place_marker "patch"
fi

if ! marker_exists "tar" ; then
    cmd 'tar -xf tar-1.35.tar.xz'
    cmd 'cd tar-1.35'
    cmd 'FORCE_UNSAFE_CONFIGURE=1  \
./configure --prefix=/usr'
    cmd 'make'
    cmd 'make install'
    cmd 'make -C doc install-html docdir=/usr/share/doc/tar-1.35'
    cmd 'cd /sources'
    cmd 'rm -rf tar-1.35'
    place_marker "tar"
fi

if ! marker_exists "texinfo" ; then
    cmd 'tar -xf texinfo-7.2.tar.xz'
    cmd 'cd texinfo-7.2'
    cmd "sed 's/! \$output_file eq/\$output_file ne/' -i tp/Texinfo/Convert/*.pm"
    cmd './configure --prefix=/usr'
    cmd 'make'
    cmd 'make install'
    cmd 'make TEXMF=/usr/share/texmf install-tex'
    cmd 'cd /sources'
    cmd 'rm -rf texinfo-7.2'
    place_marker "texinfo"
fi

if ! marker_exists "vim" ; then
    cmd 'tar -xf vim-9.1.1629.tar.gz'
    cmd 'cd vim-9.1.1629'
    cmd 'echo '"'"'#define SYS_VIMRC_FILE "/etc/vimrc"'"'"' >> src/feature.h'
    cmd './configure --prefix=/usr'
    cmd 'make'
    cmd 'make install'
    cmd 'ln -sv vim /usr/bin/vi'
    cmd 'for L in /usr/share/man/{,*/}man1/vim.1; do
    ln -sv vim.1 $(dirname $L)/vi.1;
done'
    cmd 'ln -sv ../vim/vim91/doc /usr/share/doc/vim-9.1.1629'
    cmd 'cat > /etc/vimrc << "EOF"
" Begin /etc/vimrc

" Ensure defaults are set before customizing settings, not after
source $VIMRUNTIME/defaults.vim
let skip_defaults_vim=1

set nocompatible
set backspace=2
set mouse=
syntax on
if (&term == "xterm") || (&term == "putty")
  set background=dark
endif

" End /etc/vimrc
EOF'
    cmd 'cd /sources'
    cmd 'rm -rf vim-9.1.1629'
    place_marker "vim"
fi

if ! marker_exists "markupsafe" ; then
    cmd 'tar -xf markupsafe-3.0.2.tar.gz'
    cmd 'cd markupsafe-3.0.2'
    cmd 'pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD'
    cmd 'pip3 install --no-index --find-links dist Markupsafe'
    cmd 'cd /sources'
    cmd 'rm -rf markupsafe-3.0.2'
    place_marker "markupsafe"
fi

if ! marker_exists "jinja2" ; then
    cmd 'tar -xf jinja2-3.1.6.tar.gz'
    cmd 'cd jinja2-3.1.6'
    cmd 'pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD'
    cmd 'pip3 install --no-index --find-links dist Jinja2'
    cmd 'cd /sources'
    cmd 'rm -rf jinja2-3.1.6'
    place_marker "jinja2"
fi

if ! marker_exists "udev" ; then
    cmd 'tar -xf systemd-257.8.tar.gz'
    cmd 'cd systemd-257.8'
    cmd 'sed -e '"'"'s/GROUP="render"/GROUP="video"/'"'"' \
    -e '"'"'s/GROUP="sgx", //'"'"'               \
    -i rules.d/50-udev-default.rules.in'
    cmd "sed -i '/systemd-sysctl/s/^/#/' rules.d/99-systemd.rules.in"
    cmd 'sed -e '"'"'/NETWORK_DIRS/s/systemd/udev/'"'"' \
    -i src/libsystemd/sd-network/network-util.h'
    cmd 'mkdir -p build'
    cmd 'cd       build'
    cmd 'meson setup ..                  \
        --prefix=/usr             \
        --buildtype=release       \
        -D mode=release           \
        -D dev-kvm-mode=0660      \
        -D link-udev-shared=false \
        -D logind=false           \
        -D vconsole=false'
    cmd "export udev_helpers=\$(grep \"'name' :\" ../src/udev/meson.build | \\
                      awk '{print \$3}' | tr -d \",'\" | grep -v 'udevadm')"
    cmd 'ninja udevadm systemd-hwdb \
        $(ninja -n | grep -Eo '"'"'(src/(lib)?udev|rules.d|hwdb.d)/[^ ]*'"'"') \
        $(realpath libudev.so --relative-to .)                         \
        $udev_helpers'
    cmd 'install -vm755 -d {/usr/lib,/etc}/udev/{hwdb.d,rules.d,network}'
    cmd 'install -vm755 -d /usr/{lib,share}/pkgconfig'
    cmd 'install -vm755 udevadm                             /usr/bin/'
    cmd 'install -vm755 systemd-hwdb                        /usr/bin/udev-hwdb'
    cmd 'ln      -svfn  ../bin/udevadm                      /usr/sbin/udevd'
    cmd 'cp      -av    libudev.so{,*[0-9]}                 /usr/lib/'
    cmd 'install -vm644 ../src/libudev/libudev.h            /usr/include/'
    cmd 'install -vm644 src/libudev/*.pc                    /usr/lib/pkgconfig/'
    cmd 'install -vm644 src/udev/*.pc                       /usr/share/pkgconfig/'
    cmd 'install -vm644 ../src/udev/udev.conf               /etc/udev/'
    cmd 'install -vm644 rules.d/* ../rules.d/README         /usr/lib/udev/rules.d/'
    cmd "install -vm644 \$(find ../rules.d/*.rules \\
                      -not -name '*power-switch*') /usr/lib/udev/rules.d/"
    cmd 'install -vm644 hwdb.d/*  ../hwdb.d/{*.hwdb,README} /usr/lib/udev/hwdb.d/'
    cmd 'install -vm755 $udev_helpers                       /usr/lib/udev'
    cmd 'install -vm644 ../network/99-default.link          /usr/lib/udev/network'
    cmd 'tar -xvf ../../udev-lfs-20230818.tar.xz'
    cmd 'make -f udev-lfs-20230818/Makefile.lfs install'
    cmd "tar -xf ../../systemd-man-pages-257.8.tar.xz                          \\
    --no-same-owner --strip-components=1                              \\
    -C /usr/share/man --wildcards '*/udev*' '*/libudev*'              \\
                                  '*/systemd.link.5'                  \\
                                  '*/systemd-'{hwdb,udevd.service}.8"

    cmd "sed 's|systemd/network|udev/network|'                                 \\
    /usr/share/man/man5/systemd.link.5                                \\
  > /usr/share/man/man5/udev.link.5"
    echo_prompt
    echo 'sed '"'"'s/systemd\(\\\?-\)/udev\1/'"'"' /usr/share/man/man8/systemd-hwdb.8   \'
    echo '                               > /usr/share/man/man8/udev-hwdb.8'
    sed 's/systemd\(\\\?-\)/udev\1/' /usr/share/man/man8/systemd-hwdb.8   \
                                   > /usr/share/man/man8/udev-hwdb.8
    cmd "sed 's|lib.*udevd|sbin/udevd|'                                        \\
    /usr/share/man/man8/systemd-udevd.service.8                       \\
  > /usr/share/man/man8/udevd.8"
    cmd 'rm /usr/share/man/man*/systemd*'
    cmd 'unset udev_helpers'
    cmd 'udev-hwdb update'
    cmd 'cd /sources'
    cmd 'rm -rf systemd-257.8'
    place_marker "udev"
fi

if ! marker_exists "man-db" ; then
    cmd 'tar -xf man-db-2.13.1.tar.xz'
    cmd 'cd man-db-2.13.1'
    cmd './configure --prefix=/usr                         \
            --docdir=/usr/share/doc/man-db-2.13.1 \
            --sysconfdir=/etc                     \
            --disable-setuid                      \
            --enable-cache-owner=bin              \
            --with-browser=/usr/bin/lynx          \
            --with-vgrind=/usr/bin/vgrind         \
            --with-grap=/usr/bin/grap             \
            --with-systemdtmpfilesdir=            \
            --with-systemdsystemunitdir='
    cmd 'make'
    cmd 'make install'
    cmd 'cd /sources'
    cmd 'rm -rf man-db-2.13.1'
    place_marker "man-db"
fi

if ! marker_exists "procps-ng" ; then
    cmd 'tar -xf procps-ng-4.0.5.tar.xz'
    cmd 'cd procps-ng-4.0.5'
    cmd './configure --prefix=/usr                           \
            --docdir=/usr/share/doc/procps-ng-4.0.5 \
            --disable-static                        \
            --disable-kill                          \
            --enable-watch8bit'
    cmd 'make'
    cmd 'make install'
    cmd 'cd /sources'
    cmd 'rm -rf procps-ng-4.0.5'
    place_marker "procps-ng"
fi

if ! marker_exists "util-linux" ; then
    cmd 'tar -xf util-linux-2.41.1.tar.xz'
    cmd 'cd util-linux-2.41.1'
    cmd './configure --bindir=/usr/bin     \
            --libdir=/usr/lib     \
            --runstatedir=/run    \
            --sbindir=/usr/sbin   \
            --disable-chfn-chsh   \
            --disable-login       \
            --disable-nologin     \
            --disable-su          \
            --disable-setpriv     \
            --disable-runuser     \
            --disable-pylibmount  \
            --disable-liblastlog2 \
            --disable-static      \
            --without-python      \
            --without-systemd     \
            --without-systemdsystemunitdir        \
            ADJTIME_PATH=/var/lib/hwclock/adjtime \
            --docdir=/usr/share/doc/util-linux-2.41.1'
    cmd 'make'
    cmd 'make install'
    cmd 'cd /sources'
    cmd 'rm -rf util-linux-2.41.1'
    place_marker "util-linux"
fi

if ! marker_exists "e2fsprogs" ; then
    cmd 'tar -xf e2fsprogs-1.47.3.tar.gz'
    cmd 'cd e2fsprogs-1.47.3'
    cmd 'mkdir -v build'
    cmd 'cd       build'
    cmd '../configure --prefix=/usr       \
             --sysconfdir=/etc   \
             --enable-elf-shlibs \
             --disable-libblkid  \
             --disable-libuuid   \
             --disable-uuidd     \
             --disable-fsck'
    cmd 'make'
    cmd 'make install'
    cmd 'rm -fv /usr/lib/{libcom_err,libe2p,libext2fs,libss}.a'
    cmd 'gunzip -v /usr/share/info/libext2fs.info.gz'
    cmd 'install-info --dir-file=/usr/share/info/dir /usr/share/info/libext2fs.info'
    cmd 'makeinfo -o      doc/com_err.info ../lib/et/com_err.texinfo'
    cmd 'install -v -m644 doc/com_err.info /usr/share/info'
    cmd 'install-info --dir-file=/usr/share/info/dir /usr/share/info/com_err.info'
    cmd 'cd /sources'
    cmd 'rm -rf e2fsprogs-1.47.3'
    place_marker "e2fsprogs"
fi

if ! marker_exists "sysklogd" ; then
    cmd 'tar -xf sysklogd-2.7.2.tar.gz'
    cmd 'cd sysklogd-2.7.2'
    cmd './configure --prefix=/usr      \
            --sysconfdir=/etc  \
            --runstatedir=/run \
            --without-logger   \
            --disable-static   \
            --docdir=/usr/share/doc/sysklogd-2.7.2'
    cmd 'make'
    cmd 'make install'
    cmd 'cat > /etc/syslog.conf << "EOF"
# Begin /etc/syslog.conf

auth,authpriv.* -/var/log/auth.log
*.*;auth,authpriv.none -/var/log/sys.log
daemon.* -/var/log/daemon.log
kern.* -/var/log/kern.log
mail.* -/var/log/mail.log
user.* -/var/log/user.log
*.emerg *

# Do not open any internet ports.
secure_mode 2

# End /etc/syslog.conf
EOF'
    cmd 'cd /sources'
    cmd 'rm -rf sysklogd-2.7.2'
    place_marker "sysklogd"
fi

if ! marker_exists "sysvinit" ; then
    cmd 'tar -xf sysvinit-3.14.tar.xz'
    cmd 'cd sysvinit-3.14'
    cmd 'patch -Np1 -i ../sysvinit-3.14-consolidated-1.patch'
    cmd 'make'
    cmd 'make install'
    cmd 'cd /sources'
    cmd 'rm -rf sysvinit-3.14'
    place_marker "sysvinit"
fi

if ! marker_exists "strip" ; then
    cmd 'save_usrlib="$(cd /usr/lib; ls ld-linux*[^g])
             libc.so.6
             libthread_db.so.1
             libquadmath.so.0.0.0
             libstdc++.so.6.0.34
             libitm.so.1.0.0
             libatomic.so.1.2.0"'
    cmd 'cd /usr/lib'
    cmd 'for LIB in $save_usrlib; do
    objcopy --only-keep-debug --compress-debug-sections=zstd $LIB $LIB.dbg
    cp $LIB /tmp/$LIB
    strip --strip-debug /tmp/$LIB
    objcopy --add-gnu-debuglink=$LIB.dbg /tmp/$LIB
    install -vm755 /tmp/$LIB /usr/lib
    rm /tmp/$LIB
done'
    cmd 'online_usrbin="bash find strip"'
    cmd 'online_usrlib="libbfd-2.45.so
               libsframe.so.2.0.0
               libhistory.so.8.3
               libncursesw.so.6.5
               libm.so.6
               libreadline.so.8.3
               libz.so.1.3.1
               libzstd.so.1.5.7
               $(cd /usr/lib; find libnss*.so* -type f)"'

    cmd 'for BIN in $online_usrbin; do
    cp /usr/bin/$BIN /tmp/$BIN
    strip --strip-debug /tmp/$BIN
    install -vm755 /tmp/$BIN /usr/bin
    rm /tmp/$BIN
done'
    cmd 'for LIB in $online_usrlib; do
    cp /usr/lib/$LIB /tmp/$LIB
    strip --strip-debug /tmp/$LIB
    install -vm755 /tmp/$LIB /usr/lib
    rm /tmp/$LIB
done'
    cmd 'for i in $(find /usr/lib -type f -name \*.so* ! -name \*dbg) \
         $(find /usr/lib -type f -name \*.a)                 \
         $(find /usr/{bin,sbin,libexec} -type f); do
    case "$online_usrbin $online_usrlib $save_usrlib" in
        *$(basename $i)* )
            ;;
        * ) strip --strip-debug $i
            ;;
    esac
done'
    cmd 'unset BIN LIB save_usrlib online_usrbin online_usrlib'
    place_marker "strip"
fi

if ! marker_exists "cleanup" ; then
    cmd 'rm -rf /tmp/{*,.*}'
    cmd 'find /usr/lib /usr/libexec -name \*.la -delete'
    cmd 'find /usr -depth -name $(uname -m)-lfs-linux-gnu\* | xargs rm -rf'
    cmd 'userdel -r tester'
    place_marker "cleanup"
fi

if ! marker_exists "lfs-bootscripts" ; then
    cmd 'cd /sources'
    cmd 'tar -xf lfs-bootscripts-20250827.tar.xz'
    cmd 'cd lfs-bootscripts-20250827'
    cmd 'make install'

    # Do some custom changes on boot messages.
    cmd "sed -i '/CURS_ZERO/s/0G/21G/' /lib/lsb/init-functions"
    cmd "sed -i '/evaluate_retval/d' /etc/init.d/mountvirtfs"
    cmd "sed -i '/Mounting virtual file systems/s/.*/&\\n      evaluate_retval/' /etc/init.d/mountvirtfs"
    cmd "sed -i '/mount -o /s/^\\( *\\).*/&\\
\\1evaluate_retval/' /etc/init.d/mountvirtfs"
    cmd "sed -i '/ln -sf/s/^\\( *\\).*/&\\
\\1evaluate_retval/' /etc/init.d/mountvirtfs"
    FIND_STR1="Mounting virtual file systems:"
    cmd "sed -i \"s|$FIND_STR1|$FIND_STR1\\n|\" /etc/init.d/mountvirtfs"
    FIND_STR2="Create symlinks in /dev targeting /proc:"
    cmd "sed -i \"s|$FIND_STR2|$FIND_STR2\\n|\" /etc/init.d/mountvirtfs"
    unset FIND_STR1,FIND_STR2

    cmd 'cd /sources'
    cmd 'rm -rf lfs-bootscripts-20250827'
    place_marker "lfs-bootscripts"
fi

if ! marker_exists "system-config" ; then
    cmd 'cat > /etc/sysconfig/ifconfig.ens3 << "EOF"
ONBOOT=yes
IFACE=ens3
SERVICE=ipv4-static
IP=10.0.2.15
GATEWAY=10.0.2.2
PREFIX=24
BROADCAST=10.0.2.255
EOF'
    cmd 'cat > /etc/resolv.conf << "EOF"
# Begin /etc/resolv.conf

nameserver 8.8.8.8
nameserver 10.0.2.3

# End /etc/resolv.conf
EOF'
    cmd 'echo "pris" > /etc/hostname'

    cmd 'cat > /etc/hosts << "EOF"
# Begin /etc/hosts

127.0.0.1 localhost.localdomain localhost

# End /etc/hosts
EOF'
    cmd 'cat > /etc/inittab << "EOF"
# Begin /etc/inittab

id:3:initdefault:

si::sysinit:/etc/rc.d/init.d/rc S

l0:0:wait:/etc/rc.d/init.d/rc 0
l1:S1:wait:/etc/rc.d/init.d/rc 1
l2:2:wait:/etc/rc.d/init.d/rc 2
l3:3:wait:/etc/rc.d/init.d/rc 3
l4:4:wait:/etc/rc.d/init.d/rc 4
l5:5:wait:/etc/rc.d/init.d/rc 5
l6:6:wait:/etc/rc.d/init.d/rc 6

ca:12345:ctrlaltdel:/sbin/shutdown -t1 -a -r now

su:S06:once:/sbin/sulogin
s1:1:respawn:/sbin/sulogin

1:2345:respawn:/sbin/agetty --noclear tty1 9600
2:2345:respawn:/sbin/agetty tty2 9600
3:2345:respawn:/sbin/agetty tty3 9600
4:2345:respawn:/sbin/agetty tty4 9600
5:2345:respawn:/sbin/agetty tty5 9600
6:2345:respawn:/sbin/agetty tty6 9600

#S0:2345:respawn:/sbin/agetty ttyS0 115200 vt220
S0:2345:once:/sbin/agetty --autologin root --login-program /pris/pris-rebuild-a.sh ttyS0 115200 vt220

# End /etc/inittab
EOF'
    cmd 'cat > /etc/sysconfig/clock << "EOF"
# Begin /etc/sysconfig/clock

UTC=1

# Set this to any options you might need to give to hwclock,
# such as machine hardware clock type for Alphas.
CLOCKPARAMS=

# End /etc/sysconfig/clock
EOF'
    cmd 'cat > /etc/sysconfig/console << "EOF"
# Begin /etc/sysconfig/console

UNICODE="1"
FONT="Lat2-Terminus16"

# End /etc/sysconfig/console
EOF'
    cmd 'cat > /etc/sysconfig/rc.site << "EOF"
# rc.site
# Optional parameters for boot scripts.

# Distro Information
# These values, if specified here, override the defaults
#DISTRO="Linux From Scratch" # The distro name
#DISTRO_CONTACT="lfs-dev@lists.linuxfromscratch.org" # Bug report address
#DISTRO_MINI="LFS" # Short name used in filenames for distro config

# Define custom colors used in messages printed to the screen

# Please consult `man console_codes` for more information
# under the "ECMA-48 Set Graphics Rendition" section
#
# Warning: when switching from a 8bit to a 9bit font,
# the linux console will reinterpret the bold (1;) to
# the top 256 glyphs of the 9bit font.  This does
# not affect framebuffer consoles

# These values, if specified here, override the defaults
#BRACKET="\\033[1;34m" # Blue
#FAILURE="\\033[1;31m" # Red
#INFO="\\033[1;36m"    # Cyan
#NORMAL="\\033[0;39m"  # Grey
#SUCCESS="\\033[1;32m" # Green
#WARNING="\\033[1;33m" # Yellow

# Use a colored prefix
# These values, if specified here, override the defaults
BMPREFIX=""
SUCCESS_PREFIX=""
FAILURE_PREFIX=""
WARNING_PREFIX=""

# Manually set the right edge of message output (characters)
# Useful when resetting console font during boot to override
# automatic screen width detection
COLUMNS=92

# Interactive startup
#IPROMPT="yes" # Whether to display the interactive boot prompt
#itime="3"    # The amount of time (in seconds) to display the prompt

# The total length of the distro welcome string, without escape codes
wlen=$(echo "Welcome to pris" | wc -c )
welcome_message="Welcome to pris"

# The total length of the interactive string, without escape codes
#ilen=$(echo "Press '"'"'I'"'"' to enter interactive startup" | wc -c )
#i_message="Press '"'"'${FAILURE}I${NORMAL}'"'"' to enter interactive startup"

# Set scripts to skip the file system check on reboot
#FASTBOOT=yes

# Skip reading from the console
#HEADLESS=yes

# Write out fsck progress if yes
#VERBOSE_FSCK=no

# Speed up boot without waiting for settle in udev
#OMIT_UDEV_SETTLE=y

# Speed up boot without waiting for settle in udev_retry
#OMIT_UDEV_RETRY_SETTLE=yes

# Skip cleaning /tmp if yes
#SKIPTMPCLEAN=no

# For setclock
#UTC=1
#CLOCKPARAMS=

# For consolelog (Note that the default, 7=debug, is noisy)
#LOGLEVEL=7

# For network
#HOSTNAME=mylfs

# Delay between TERM and KILL signals at shutdown
#KILLDELAY=3

# Optional sysklogd parameters
#SYSKLOGD_PARMS="-m 0"

# Console parameters
#UNICODE=1
#KEYMAP="de-latin1"
#KEYMAP_CORRECTIONS="euro2"
#FONT="lat0-16 -m 8859-15"
#LEGACY_CHARSET=
EOF'
    cmd 'cat > /etc/profile << "EOF"
# Begin /etc/profile

for i in $(locale); do
  unset ${i%=*}
done

if [[ "$TERM" = linux ]]; then
  export LANG=C.UTF-8
else
  export LANG=en_US.ISO-8859-1
fi

# End /etc/profile
EOF'
    cmd 'cat > /etc/inputrc << "EOF"
# Begin /etc/inputrc
# Modified by Chris Lynn <roryo@roryo.dynup.net>

# Allow the command prompt to wrap to the next line
set horizontal-scroll-mode Off

# Enable 8-bit input
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
"\eOd": backward-word
"\eOc": forward-word

# for linux console
"\e[1~": beginning-of-line
"\e[4~": end-of-line
"\e[5~": beginning-of-history
"\e[6~": end-of-history
"\e[3~": delete-char
"\e[2~": quoted-insert

# for xterm
"\eOH": beginning-of-line
"\eOF": end-of-line

# for Konsole
"\e[H": beginning-of-line
"\e[F": end-of-line

# End /etc/inputrc
EOF'
    cmd 'cat > /etc/shells << "EOF"
# Begin /etc/shells

/bin/sh
/bin/bash

# End /etc/shells
EOF'
    cmd 'cat > /etc/fstab << "EOF"
# Begin /etc/fstab

# file system  mount-point    type     options             dump  fsck
#                                                                order

/dev/sda1      /              ext4     defaults            1     1
/dev/sda2      swap           swap     pri=1               0     0
/dev/sdb       /pris          ext4     defaults            0     0
proc           /proc          proc     nosuid,noexec,nodev 0     0
sysfs          /sys           sysfs    nosuid,noexec,nodev 0     0
devpts         /dev/pts       devpts   gid=5,mode=620      0     0
tmpfs          /run           tmpfs    defaults            0     0
devtmpfs       /dev           devtmpfs mode=0755,nosuid    0     0
tmpfs          /dev/shm       tmpfs    nosuid,nodev        0     0
cgroup2        /sys/fs/cgroup cgroup2  nosuid,noexec,nodev 0     0

# End /etc/fstab
EOF'
    place_marker "system-config"
fi

if ! marker_exists "linux" ; then
    cmd 'tar -xf linux-6.16.1.tar.xz'
    cmd 'cd linux-6.16.1'
    cmd 'make mrproper'
    cmd 'gunzip -c /proc/config.gz > .config'
    cmd 'make'
    cmd 'make modules_install'
    cmd 'cp -iv arch/x86/boot/bzImage /boot/vmlinuz-6.16.1-lfs-12.4'
    cmd 'cp -iv System.map /boot/System.map-6.16.1'
    cmd 'cp -iv .config /boot/config-6.16.1'
    cmd 'cp -r Documentation -T /usr/share/doc/linux-6.16.1'
    cmd 'install -v -m755 -d /etc/modprobe.d'
    cmd "cat > /etc/modprobe.d/usb.conf << \"EOF\"
# Begin /etc/modprobe.d/usb.conf

install ohci_hcd /sbin/modprobe ehci_hcd ; /sbin/modprobe -i ohci_hcd ; true
install uhci_hcd /sbin/modprobe ehci_hcd ; /sbin/modprobe -i uhci_hcd ; true

# End /etc/modprobe.d/usb.conf
EOF"
    cmd 'cd /sources'
    cmd 'rm -rf linux-6.16.1'
    place_marker "linux"
fi

if marker_exists "dl-libtasn1" && ! marker_exists "libtasn1" ; then
    cmd 'tar -xf libtasn1-4.20.0.tar.gz'
    cmd 'cd libtasn1-4.20.0'
    cmd './configure --prefix=/usr --disable-static &&
make'
    cmd 'make install'
    cmd 'make -C doc/reference install-data-local'
    cmd 'cd /sources'
    cmd 'rm -rf libtasn1-4.20.0'
    place_marker "libtasn1"
fi

if marker_exists "dl-p11-kit" && ! marker_exists "p11-kit" ; then
    cmd 'tar -xf p11-kit-0.25.5.tar.xz'
    cmd 'cd p11-kit-0.25.5'
    cmd "sed '20,\$ d' -i trust/trust-extract-compat &&
cat >> trust/trust-extract-compat << \"EOF\"
# Copy existing anchor modifications to /etc/ssl/local
/usr/libexec/make-ca/copy-trust-modifications

# Update trust stores
/usr/sbin/make-ca -r
EOF"
    cmd 'mkdir p11-build &&
cd    p11-build &&
meson setup ..            \
      --prefix=/usr       \
      --buildtype=release \
      -D trust_paths=/etc/pki/anchors &&
ninja'
    cmd 'ninja install &&
ln -sfv /usr/libexec/p11-kit/trust-extract-compat \
        /usr/bin/update-ca-certificates'
    cmd 'ln -sfv ./pkcs11/p11-kit-trust.so /usr/lib/libnssckbi.so'
    cmd 'cd /sources'
    cmd 'rm -rf p11-kit-0.25.5'
    place_marker "p11-kit"
fi

if marker_exists "dl-make-ca" && ! marker_exists "make-ca" ; then
    cmd 'tar -xf make-ca-1.16.1.tar.gz'
    cmd 'cd make-ca-1.16.1'
    cmd 'make install &&
install -vdm755 /etc/ssl/local'
    cmd '/usr/sbin/make-ca -g'
    cmd 'export _PIP_STANDALONE_CERT=/etc/pki/tls/certs/ca-bundle.crt'
    cmd 'mkdir -pv /etc/profile.d &&
cat > /etc/profile.d/pythoncerts.sh << "EOF"
# Begin /etc/profile.d/pythoncerts.sh

export _PIP_STANDALONE_CERT=/etc/pki/tls/certs/ca-bundle.crt

# End /etc/profile.d/pythoncerts.sh
EOF'
    cmd 'cd /sources'
    cmd 'rm -rf make-ca-1.16.1'
    place_marker "make-ca"
fi

if marker_exists "libtasn1" \
    && marker_exists "p11-kit" \
    && marker_exists "make-ca" \
    && marker_exists "dl-wget" \
    && ! marker_exists "wget" ; then
    cmd 'tar -xf wget-1.25.0.tar.gz'
    cmd 'cd wget-1.25.0'
    cmd './configure --prefix=/usr      \
            --sysconfdir=/etc  \
            --with-ssl=openssl &&
make'
    cmd 'make install'
    cmd 'cd /sources'
    cmd 'rm -rf wget-1.25.0'
    place_marker "wget"
fi

if ! marker_exists "openssh" ; then
    cmd 'wget https://ftp.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-10.0p1.tar.gz'
    cmd 'echo "689148621a2eaa734497b12bed1c5202 openssh-10.0p1.tar.gz" \
    | md5sum -c'
    cmd 'tar -xf openssh-10.0p1.tar.gz'
    cmd 'cd openssh-10.0p1'
    cmd "install -v -g sys -m700 -d /var/lib/sshd &&

groupadd -g 50 sshd        &&
useradd  -c 'sshd PrivSep' \\
         -d /var/lib/sshd  \\
         -g sshd           \\
         -s /bin/false     \\
         -u 50 sshd"
    cmd './configure --prefix=/usr                            \
            --sysconfdir=/etc/ssh                    \
            --with-privsep-path=/var/lib/sshd        \
            --with-default-path=/usr/bin             \
            --with-superuser-path=/usr/sbin:/usr/bin \
            --with-pid-dir=/run                      &&
make'
    cmd 'make install &&
install -v -m755    contrib/ssh-copy-id /usr/bin     &&

install -v -m644    contrib/ssh-copy-id.1 \
                    /usr/share/man/man1              &&
install -v -m755 -d /usr/share/doc/openssh-10.0p1    &&
install -v -m644    INSTALL LICENCE OVERVIEW README* \
                    /usr/share/doc/openssh-10.0p1'
    cmd 'echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config &&
echo "PermitEmptyPasswords yes" >> /etc/ssh/sshd_config &&
echo "PermitRootLogin yes" >> /etc/ssh/sshd_config &&
echo "KbdInteractiveAuthentication no" >> /etc/ssh/sshd_config'
    cmd 'tar -xf ../blfs-bootscripts-20250225.tar.xz'
    cmd 'cd blfs-bootscripts-20250225'
    cmd 'make install-sshd'
    cmd 'cd /sources'
    cmd 'rm -rf openssh-10.0p1'
    place_marker "openssh"
fi

if ! marker_exists "lfs-release" ; then
    cmd 'echo 12.4 > /etc/lfs-release'
    cmd 'cat > /etc/lsb-release << "EOF"
DISTRIB_ID="Linux From Scratch"
DISTRIB_RELEASE="12.4"
DISTRIB_CODENAME="pris"
DISTRIB_DESCRIPTION="Linux From Scratch"
EOF'
    cmd 'cat > /etc/os-release << "EOF"
NAME="Linux From Scratch"
VERSION="12.4"
ID=lfs
PRETTY_NAME="Linux From Scratch 12.4"
VERSION_CODENAME="pris"
HOME_URL="https://www.linuxfromscratch.org/lfs/"
RELEASE_TYPE="stable"
EOF'
    place_marker "lfs-release"
fi

if ! marker_exists "which" ; then
    cmd 'wget https://ftp.gnu.org/gnu/which/which-2.23.tar.gz'
    cmd 'echo "689148621a2eaa734497b12bed1c5202 openssh-10.0p1.tar.gz" \
    | md5sum -c'
    cmd 'tar -xf which-2.23.tar.gz'
    cmd 'cd which-2.23'
    cmd './configure --prefix=/usr &&
make'
    cmd 'make install'
    cmd 'cd /sources'
    cmd 'rm -rf which-2.23'
    place_marker "which"
fi

if ! marker_exists "zsh" ; then
    cmd 'wget https://www.zsh.org/pub/zsh-5.9.1.tar.xz'
    cmd 'tar -xf zsh-5.9.1.tar.xz'
    cmd 'cd zsh-5.9.1'
    cmd "sed -e 's/set_from_init_file/texinfo_&/' \\
    -i Doc/Makefile.in"
    cmd "sed -e 's/^main/int &/'      \\
    -e 's/exit(/return(/'    \\
    -i aczsh.m4 configure.ac &&
sed -e 's/test = /&(char**)/' \\
    -i configure.ac           &&
autoconf"
    cmd "sed -e 's|/etc/z|/etc/zsh/z|g' \\
    -i Doc/*.*"
    cmd './configure --prefix=/usr            \
            --sysconfdir=/etc/zsh    \
            --enable-etcdir=/etc/zsh \
            --enable-cap             \
            --enable-gdbm            &&
make                                 &&
makeinfo  Doc/zsh.texi --html      -o Doc/html &&
makeinfo  Doc/zsh.texi --plaintext -o zsh.txt  &&
makeinfo  Doc/zsh.texi --html --no-split --no-headers -o zsh.html'
    cmd 'make install                                                    &&
make infodir=/usr/share/info install.info                       &&
make htmldir=/usr/share/doc/zsh-5.9/html install.html           &&
install -v -m644 zsh.{html,txt} Etc/FAQ /usr/share/doc/zsh-5.9'
    cmd 'cat >> /etc/shells << "EOF"
/bin/zsh
EOF'
    cmd 'cd /sources'
    cmd 'rm -rf zsh-5.9.1'
    place_marker "zsh"
fi

if ! marker_exists "libunistring" ; then
    cmd 'wget https://ftp.gnu.org/gnu/libunistring/libunistring-1.3.tar.xz'
    cmd 'echo "57dfd9e4eba93913a564aa14eab8052e libunistring-1.3.tar.xz" \
    | md5sum -c'
    cmd 'tar -xf libunistring-1.3.tar.xz'
    cmd 'cd libunistring-1.3'
    cmd './configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/libunistring-1.3 &&
make'
    cmd 'make install'
    cmd 'cd /sources'
    cmd 'rm -rf libunistring-1.3'
    place_marker "libunistring"
fi

if ! marker_exists "libidn2" ; then
    cmd 'wget https://ftp.gnu.org/gnu/libidn/libidn2-2.3.8.tar.gz'
    cmd 'echo "a8e113e040d57a523684e141970eea7a libidn2-2.3.8.tar.gz" \
    | md5sum -c'
    cmd 'tar -xf libidn2-2.3.8.tar.gz'
    cmd 'cd libidn2-2.3.8'
    cmd './configure --prefix=/usr --disable-static &&
make'
    cmd 'make install'
    cmd 'cd /sources'
    cmd 'rm -rf libidn2-2.3.8'
    place_marker "libidn2"
fi

if ! marker_exists "libpsl" ; then
    cmd 'wget https://github.com/rockdaboot/libpsl/releases/download/0.21.5/libpsl-0.21.5.tar.gz'
    cmd 'echo "870a798ee9860b6e77896548428dba7b libpsl-0.21.5.tar.gz" \
    | md5sum -c'
    cmd 'tar -xf libpsl-0.21.5.tar.gz'
    cmd 'cd libpsl-0.21.5'
    cmd 'mkdir build &&
cd    build &&
meson setup --prefix=/usr --buildtype=release &&
ninja'
    cmd 'ninja install'
    cmd 'cd /sources'
    cmd 'rm -rf libpsl-0.21.5'
    place_marker "libpsl"
fi

if ! marker_exists "curl" ; then
    cmd 'wget https://curl.se/download/curl-8.15.0.tar.xz'
    cmd 'echo "b8872bb6cc5d18d03bea8ff5090b2b81 curl-8.15.0.tar.xz" \
    | md5sum -c'
    cmd 'tar -xf curl-8.15.0.tar.xz'
    cmd 'cd curl-8.15.0'
    cmd './configure --prefix=/usr    \
            --disable-static \
            --with-openssl   \
            --with-ca-path=/etc/ssl/certs &&
make'
    cmd 'make install &&
rm -rf docs/examples/.deps &&
find docs \( -name Makefile\* -o  \
                -name \*.1       -o  \
                -name \*.3       -o  \
                -name CMakeLists.txt \) -delete &&
cp -v -R docs -T /usr/share/doc/curl-8.15.0'
    cmd 'cd /sources'
    cmd 'rm -rf curl-8.15.0'
    place_marker "curl"
fi

if ! marker_exists "asciidoc" ; then
    cmd 'wget https://files.pythonhosted.org/packages/source/a/asciidoc/asciidoc-10.2.1.tar.gz'
    cmd 'echo "460824075b51381a4b5f478c60a18165 asciidoc-10.2.1.tar.gz" \
    | md5sum -c'
    cmd 'tar -xf asciidoc-10.2.1.tar.gz'
    cmd 'cd asciidoc-10.2.1'
    cmd 'pip3 wheel -w dist --no-build-isolation --no-deps --no-cache-dir $PWD'
    cmd 'pip3 install --no-index --find-links dist --no-user asciidoc'
    cmd 'cd /sources'
    cmd 'rm -rf asciidoc-10.2.1'
    place_marker "asciidoc"
fi

if ! marker_exists "icu" ; then
    cmd 'wget https://github.com/unicode-org/icu/releases/download/release-77-1/icu4c-77_1-src.tgz'
    cmd 'echo "bc0132b4c43db8455d2446c3bae58898 icu4c-77_1-src.tgz" \
    | md5sum -c'
    cmd 'tar -xf icu4c-77_1-src.tgz'
    cmd 'cd icu'
    cmd 'case $(uname -m) in
  i?86) sed -e "s/U_PLATFORM_IS_LINUX_BASED/__X86_64__ \&\& &/" \
            -i source/test/intltest/ustrtest.cpp ;;
esac'
    cmd 'cd source                 &&
./configure --prefix=/usr &&
make'
    cmd 'make install'
    cmd 'cd /sources'
    cmd 'rm -rf icu'
    place_marker "icu"
fi

if ! marker_exists "libxml2" ; then
    cmd 'wget https://download.gnome.org/sources/libxml2/2.14/libxml2-2.14.5.tar.xz'
    cmd 'echo "59aac4e5d1d350ba2c4bddf1f7bc5098 libxml2-2.14.5.tar.xz" \
    | md5sum -c'
    cmd 'tar -xf libxml2-2.14.5.tar.xz'
    cmd 'cd libxml2-2.14.5'
    cmd './configure --prefix=/usr     \
            --sysconfdir=/etc \
            --disable-static  \
            --with-history    \
            --with-icu        \
            PYTHON=/usr/bin/python3 \
            --docdir=/usr/share/doc/libxml2-2.14.5 &&
make'
    cmd 'make install'
    cmd "rm -vf /usr/lib/libxml2.la &&
sed '/libs=/s/xml2.*/xml2\"/' -i /usr/bin/xml2-config"
    cmd 'cd /sources'
    cmd 'rm -rf libxml2-2.14.5'
    place_marker "libxml2"
fi

if ! marker_exists "libarchive" ; then
    cmd 'wget https://github.com/libarchive/libarchive/releases/download/v3.8.1/libarchive-3.8.1.tar.xz'
    cmd 'echo "80fd1a7acc4da7c7d4a5f9f96df6e3ff libarchive-3.8.1.tar.xz" \
    | md5sum -c'
    cmd 'tar -xf libarchive-3.8.1.tar.xz'
    cmd 'cd libarchive-3.8.1'
    cmd './configure --prefix=/usr --disable-static &&
make'
    cmd 'make install'
    cmd 'ln -sfv bsdunzip /usr/bin/unzip'
    cmd 'cd /sources'
    cmd 'rm -rf libarchive-3.8.1'
    place_marker "libarchive"
fi

if ! marker_exists "docbook-xml" ; then
    cmd 'wget https://archive.docbook.org/xml/4.5/docbook-xml-4.5.zip'
    cmd 'echo "03083e288e87a7e829e437358da7ef9e docbook-xml-4.5.zip" \
    | md5sum -c'
    cmd 'unzip docbook-xml-4.5.zip -d docbook-xml-4.5'
    cmd 'cd docbook-xml-4.5'
    cmd 'install -v -d -m755 /usr/share/xml/docbook/xml-dtd-4.5         &&
install -v -d -m755 /etc/xml                                   &&
cp -v -af --no-preserve=ownership docbook.cat *.dtd ent/ *.mod \
    /usr/share/xml/docbook/xml-dtd-4.5'
    cmd 'if [ ! -e /etc/xml/docbook ]; then
    xmlcatalog --noout --create /etc/xml/docbook
fi &&

xmlcatalog --noout --add "public"                            \
    "-//OASIS//DTD DocBook XML V4.5//EN"                     \
    "http://www.oasis-open.org/docbook/xml/4.5/docbookx.dtd" \
    /etc/xml/docbook &&

xmlcatalog --noout --add "public"                            \
    "-//OASIS//DTD DocBook XML CALS Table Model V4.5//EN"    \
    "file:///usr/share/xml/docbook/xml-dtd-4.5/calstblx.dtd" \
    /etc/xml/docbook &&

xmlcatalog --noout --add "public"                            \
    "-//OASIS//DTD XML Exchange Table Model 19990315//EN"    \
    "file:///usr/share/xml/docbook/xml-dtd-4.5/soextblx.dtd" \
    /etc/xml/docbook &&

xmlcatalog --noout --add "public"                              \
    "-//OASIS//ELEMENTS DocBook XML Information Pool V4.5//EN" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5/dbpoolx.mod"    \
    /etc/xml/docbook &&

xmlcatalog --noout --add "public"                                \
    "-//OASIS//ELEMENTS DocBook XML Document Hierarchy V4.5//EN" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5/dbhierx.mod"      \
    /etc/xml/docbook &&

xmlcatalog --noout --add "public"                            \
    "-//OASIS//ELEMENTS DocBook XML HTML Tables V4.5//EN"    \
    "file:///usr/share/xml/docbook/xml-dtd-4.5/htmltblx.mod" \
    /etc/xml/docbook &&

xmlcatalog --noout --add "public"                           \
    "-//OASIS//ENTITIES DocBook XML Notations V4.5//EN"     \
    "file:///usr/share/xml/docbook/xml-dtd-4.5/dbnotnx.mod" \
    /etc/xml/docbook &&

xmlcatalog --noout --add "public"                                \
    "-//OASIS//ENTITIES DocBook XML Character Entities V4.5//EN" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5/dbcentx.mod"      \
    /etc/xml/docbook &&

xmlcatalog --noout --add "public"                                         \
    "-//OASIS//ENTITIES DocBook XML Additional General Entities V4.5//EN" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5/dbgenent.mod"              \
    /etc/xml/docbook &&

xmlcatalog --noout --add "rewriteSystem"        \
    "http://www.oasis-open.org/docbook/xml/4.5" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5" \
    /etc/xml/docbook &&

xmlcatalog --noout --add "rewriteURI"           \
    "http://www.oasis-open.org/docbook/xml/4.5" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5" \
    /etc/xml/docbook'
    cmd 'if [ ! -e /etc/xml/catalog ]; then
    xmlcatalog --noout --create /etc/xml/catalog
fi &&

xmlcatalog --noout --add "delegatePublic" \
    "-//OASIS//ENTITIES DocBook XML"      \
    "file:///etc/xml/docbook"             \
    /etc/xml/catalog                      &&

xmlcatalog --noout --add "delegatePublic" \
    "-//OASIS//DTD DocBook XML"           \
    "file:///etc/xml/docbook"             \
    /etc/xml/catalog                      &&

xmlcatalog --noout --add "delegateSystem" \
    "http://www.oasis-open.org/docbook/"  \
    "file:///etc/xml/docbook"             \
    /etc/xml/catalog                      &&

xmlcatalog --noout --add "delegateURI"    \
    "http://www.oasis-open.org/docbook/"  \
    "file:///etc/xml/docbook"             \
    /etc/xml/catalog'
    cmd 'for DTDVERSION in 4.1.2 4.2 4.3 4.4
do
    xmlcatalog --noout --add "public"                                  \
    "-//OASIS//DTD DocBook XML V$DTDVERSION//EN"                     \
    "http://www.oasis-open.org/docbook/xml/$DTDVERSION/docbookx.dtd" \
    /etc/xml/docbook

    xmlcatalog --noout --add "rewriteSystem"              \
    "http://www.oasis-open.org/docbook/xml/$DTDVERSION" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5"         \
    /etc/xml/docbook

    xmlcatalog --noout --add "rewriteURI"                 \
    "http://www.oasis-open.org/docbook/xml/$DTDVERSION" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5"         \
    /etc/xml/docbook

    xmlcatalog --noout --add "delegateSystem"              \
    "http://www.oasis-open.org/docbook/xml/$DTDVERSION/" \
    "file:///etc/xml/docbook"                            \
    /etc/xml/catalog

    xmlcatalog --noout --add "delegateURI"                 \
    "http://www.oasis-open.org/docbook/xml/$DTDVERSION/" \
    "file:///etc/xml/docbook"                            \
    /etc/xml/catalog
done'
    cmd 'cd /sources'
    cmd 'rm -rf docbook-xml-4.5'
    place_marker "docbook-xml"
fi

if ! marker_exists "docbook-xsl-nons" ; then
    cmd 'wget https://github.com/docbook/xslt10-stylesheets/releases/download/release/1.79.2/docbook-xsl-nons-1.79.2.tar.bz2'
    cmd 'wget https://www.linuxfromscratch.org/patches/blfs/12.4/docbook-xsl-nons-1.79.2-stack_fix-1.patch'
    cmd 'echo "2666d1488d6ced1551d15f31d7ed8c38 docbook-xsl-nons-1.79.2.tar.bz2" \
    | md5sum -c'
    cmd 'tar -xf docbook-xsl-nons-1.79.2.tar.bz2'
    cmd 'cd docbook-xsl-nons-1.79.2'
    cmd 'patch -Np1 -i ../docbook-xsl-nons-1.79.2-stack_fix-1.patch'
    cmd 'install -v -m755 -d /usr/share/xml/docbook/xsl-stylesheets-nons-1.79.2 &&
cp -v -R VERSION assembly common eclipse epub epub3 extensions fo        \
         highlighting html htmlhelp images javahelp lib manpages params  \
         profiling roundtrip slides template tests tools webhelp website \
         xhtml xhtml-1_1 xhtml5                                          \
    /usr/share/xml/docbook/xsl-stylesheets-nons-1.79.2 &&
ln -s VERSION /usr/share/xml/docbook/xsl-stylesheets-nons-1.79.2/VERSION.xsl &&
install -v -m644 -D README \
                    /usr/share/doc/docbook-xsl-nons-1.79.2/README.txt &&
install -v -m644    RELEASE-NOTES* NEWS* \
                    /usr/share/doc/docbook-xsl-nons-1.79.2'
    cmd 'if [ ! -d /etc/xml ]; then install -v -m755 -d /etc/xml; fi &&
if [ ! -f /etc/xml/catalog ]; then
    xmlcatalog --noout --create /etc/xml/catalog
fi &&

xmlcatalog --noout --add "rewriteSystem"                         \
            "http://cdn.docbook.org/release/xsl-nons/1.79.2"     \
            "/usr/share/xml/docbook/xsl-stylesheets-nons-1.79.2" \
            /etc/xml/catalog &&

xmlcatalog --noout --add "rewriteSystem"                         \
            "https://cdn.docbook.org/release/xsl-nons/1.79.2"    \
            "/usr/share/xml/docbook/xsl-stylesheets-nons-1.79.2" \
            /etc/xml/catalog &&

xmlcatalog --noout --add "rewriteURI"                            \
            "http://cdn.docbook.org/release/xsl-nons/1.79.2"     \
            "/usr/share/xml/docbook/xsl-stylesheets-nons-1.79.2" \
            /etc/xml/catalog &&

xmlcatalog --noout --add "rewriteURI"                            \
            "https://cdn.docbook.org/release/xsl-nons/1.79.2"    \
            "/usr/share/xml/docbook/xsl-stylesheets-nons-1.79.2" \
            /etc/xml/catalog &&

xmlcatalog --noout --add "rewriteSystem"                         \
            "http://cdn.docbook.org/release/xsl-nons/current"    \
            "/usr/share/xml/docbook/xsl-stylesheets-nons-1.79.2" \
            /etc/xml/catalog &&

xmlcatalog --noout --add "rewriteSystem"                         \
            "https://cdn.docbook.org/release/xsl-nons/current"   \
            "/usr/share/xml/docbook/xsl-stylesheets-nons-1.79.2" \
            /etc/xml/catalog &&

xmlcatalog --noout --add "rewriteURI"                            \
            "http://cdn.docbook.org/release/xsl-nons/current"    \
            "/usr/share/xml/docbook/xsl-stylesheets-nons-1.79.2" \
            /etc/xml/catalog &&

xmlcatalog --noout --add "rewriteURI"                            \
            "https://cdn.docbook.org/release/xsl-nons/current"   \
            "/usr/share/xml/docbook/xsl-stylesheets-nons-1.79.2" \
            /etc/xml/catalog &&

xmlcatalog --noout --add "rewriteSystem"                         \
            "http://docbook.sourceforge.net/release/xsl/current" \
            "/usr/share/xml/docbook/xsl-stylesheets-nons-1.79.2" \
            /etc/xml/catalog &&

xmlcatalog --noout --add "rewriteURI"                            \
            "http://docbook.sourceforge.net/release/xsl/current" \
            "/usr/share/xml/docbook/xsl-stylesheets-nons-1.79.2" \
            /etc/xml/catalog'
    cmd 'cd /sources'
    cmd 'rm -rf docbook-xsl-nons-1.79.2'
    place_marker "docbook-xsl-nons"
fi

if ! marker_exists "libxslt" ; then
    cmd 'wget https://download.gnome.org/sources/libxslt/1.1/libxslt-1.1.43.tar.xz'
    cmd 'echo "5dc0179c81be7a3082b43030ecfdebd4 libxslt-1.1.43.tar.xz" \
    | md5sum -c'
    cmd 'tar -xf libxslt-1.1.43.tar.xz'
    cmd 'cd libxslt-1.1.43'
    cmd './configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/libxslt-1.1.43 &&
make'
    cmd 'make install'
    cmd 'cd /sources'
    cmd 'rm -rf libxslt-1.1.43'
    place_marker "libxslt"
fi

if ! marker_exists "xmlto" ; then
    cmd 'wget https://pagure.io/xmlto/archive/0.0.29/xmlto-0.0.29.tar.gz'
    cmd 'echo "556f2642cdcd005749bd4c08bc621c37 xmlto-0.0.29.tar.gz" \
    | md5sum -c'
    cmd 'tar -xf xmlto-0.0.29.tar.gz'
    cmd 'cd xmlto-0.0.29'
    cmd 'autoreconf -fiv                                  &&
LINKS="/usr/bin/links" ./configure --prefix=/usr &&
make'
    cmd 'make install'
    cmd 'cd /sources'
    cmd 'rm -rf xmlto-0.0.29'
    place_marker "xmlto"
fi

if ! marker_exists "git" ; then
    cmd 'wget https://www.kernel.org/pub/software/scm/git/git-2.50.1.tar.xz'
    cmd 'echo "2cb96fae126d66f8ff23a68f8dd5d748 git-2.50.1.tar.xz" \
    | md5sum -c'
    cmd 'tar -xf git-2.50.1.tar.xz'
    cmd 'cd git-2.50.1'
    cmd './configure --prefix=/usr \
            --with-gitconfig=/etc/gitconfig \
            --with-python=python3 &&
make'
    cmd 'make man'
    cmd 'make perllibdir=/usr/lib/perl5/5.42/site_perl install'
    cmd 'make install-man'
    cmd 'cd /sources'
    cmd 'rm -rf git-2.50.1'
    place_marker "git"
fi

if ! marker_exists "libuv" ; then
    cmd 'wget https://dist.libuv.org/dist/v1.51.0/libuv-v1.51.0.tar.gz'
    cmd 'echo "5e0109e19c3fed3a8cbecb958de39afa libuv-v1.51.0.tar.gz" \
    | md5sum -c'
    cmd 'tar -xf libuv-v1.51.0.tar.gz'
    cmd 'cd libuv-v1.51.0'
    cmd 'sh autogen.sh                              &&
./configure --prefix=/usr --disable-static &&
make '
    cmd 'make install'
    cmd 'cd /sources'
    cmd 'rm -rf libuv-v1.51.0'
    place_marker "libuv"
fi

if ! marker_exists "nghttp2" ; then
    cmd 'wget https://github.com/nghttp2/nghttp2/releases/download/v1.66.0/nghttp2-1.66.0.tar.xz'
    cmd 'echo "295c22437cc44e1634a2b82ea93df747 nghttp2-1.66.0.tar.xz" \
    | md5sum -c'
    cmd 'tar -xf nghttp2-1.66.0.tar.xz'
    cmd 'cd nghttp2-1.66.0'
    cmd './configure --prefix=/usr     \
            --disable-static  \
            --enable-lib-only \
            --docdir=/usr/share/doc/nghttp2-1.66.0 &&
make'
    cmd 'make install'
    cmd 'cd /sources'
    cmd 'rm -rf nghttp2-1.66.0'
    place_marker "nghttp2"
fi

if ! marker_exists "cmake" ; then
    cmd 'wget https://cmake.org/files/v4.1/cmake-4.1.0.tar.gz'
    cmd 'echo "80ae27faba5068c8ec12c77bf00e6db3 cmake-4.1.0.tar.gz" \
    | md5sum -c'
    cmd 'tar -xf cmake-4.1.0.tar.gz'
    cmd 'cd cmake-4.1.0'
    cmd "sed -i '/\"lib64\"/s/64//' Modules/GNUInstallDirs.cmake &&
./bootstrap --prefix=/usr        \\
            --system-libs        \\
            --mandir=/share/man  \\
            --no-system-jsoncpp  \\
            --no-system-cppdap   \\
            --no-system-librhash \\
            --docdir=/share/doc/cmake-4.1.0 &&
make"
    cmd 'make install'
    cmd 'cd /sources'
    cmd 'rm -rf cmake-4.1.0'
    place_marker "cmake"
fi

if ! marker_exists "redis" ; then
    cmd 'wget -O redis-8.6.3.tar.gz https://github.com/redis/redis/archive/refs/tags/8.6.3.tar.gz'
    cmd 'tar -xf redis-8.6.3.tar.gz'
    cmd 'cd redis-8.6.3'
    cmd 'export BUILD_TLS=yes'
    cmd 'export BUILD_WITH_MODULES=no'
    cmd 'export INSTALL_RUST_TOOLCHAIN=no'
    cmd 'export DISABLE_WERRORS=yes'
    cmd 'make PREFIX=/usr -j "$(nproc)" all'
    cmd './src/redis-server --version'
    cmd './src/redis-cli --version'
    cmd 'make PREFIX=/usr install'
    cmd 'cd /sources'
    cmd 'rm -rf redis-8.6.3'
    place_marker "redis"
fi

if ! marker_exists "mlflow" ; then
    cmd 'pip3 install --upgrade "mlflow>=3.1"'
    place_marker "mlflow"
fi

if ! marker_exists "ray" ; then
    cmd 'pip3 install -U "ray[data,train,tune,serve]"'
    place_marker "ray"
fi

if ! marker_exists "torch" ; then
    cmd 'pip3 install torch torchvision'
    place_marker "torch"
fi

if ! marker_exists "llvm" ; then
    cmd 'git clone --depth 1 --branch release/20.x https://github.com/llvm/llvm-project llvm-project-20'
    cmd 'cd llvm-project-20'
    cmd 'git checkout release/20.x'
    cmd $'grep -rl \'#!.*python\' | xargs sed -i \'1s/python$/python3/\''
    cmd 'mkdir -v build &&
cd       build &&
CC=gcc CXX=g++                             \
cmake ../llvm                              \
    -D CMAKE_INSTALL_PREFIX=/usr           \
    -D CMAKE_SKIP_INSTALL_RPATH=ON         \
    -D LLVM_ENABLE_FFI=ON                  \
    -D CMAKE_BUILD_TYPE=Release            \
    -D LLVM_BUILD_LLVM_DYLIB=ON            \
    -D LLVM_LINK_LLVM_DYLIB=ON             \
    -D LLVM_ENABLE_PROJECTS="lld;clang"    \
    -D LLVM_ENABLE_RTTI=ON                 \
    -D LLVM_ENABLE_LIBXML2=OFF             \
    -D LLVM_ENABLE_LIBEDIT=OFF             \
    -D LLVM_ENABLE_ASSERTIONS=ON           \
    -D LLVM_PARALLEL_LINK_JOBS=1           \
    -D LLVM_BINUTILS_INCDIR=/usr/include   \
    -D LLVM_INCLUDE_BENCHMARKS=OFF         \
    -D CLANG_DEFAULT_PIE_ON_LINUX=ON       \
    -D CLANG_CONFIG_FILE_SYSTEM_DIR=/etc/clang \
    -W no-dev -G Ninja                     &&
ninja'
    cmd 'ninja install'
    cmd 'mkdir -pv /etc/clang &&
for i in clang clang++; do
    echo -fstack-protector-strong > /etc/clang/$i.cfg
done'
    cmd 'cd /sources'
    cmd 'rm -rf llvm-project-20'
    place_marker "llvm"
fi

if ! marker_exists "zig" ; then
    cmd 'wget https://ziglang.org/download/0.15.2/zig-0.15.2.tar.xz'
    cmd 'tar -xf zig-0.15.2.tar.xz'
    cmd 'cd zig-0.15.2'
    cmd 'mkdir build'
    cmd 'cd build'
    cmd 'cmake .. \
    -D CMAKE_INSTALL_PREFIX=/usr \
    -D CMAKE_BUILD_TYPE=Release \
    -D ZIG_EXTRA_BUILD_ARGS="--maxrss;8000000000"'
    cmd 'make'
    cmd 'make install'
    cmd 'cd /sources'
    cmd 'rm -rf zig-0.15.2'
    place_marker "zig"
fi

cmd 'exit'
