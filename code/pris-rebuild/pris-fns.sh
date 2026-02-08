shopt -s extglob

declare DATA_IO=3
declare SGNL_IO=4
declare DATA_IO_PORT="/dev/tcp/roy/9000"
declare SGNL_IO_PORT="/dev/tcp/roy/9001"

declare PRIS_DIR="/pris"
declare PRIS_LOG="${PRIS_DIR}/pris.log"
declare PRIS_MARKER_DIR="${PRIS_DIR}/markers"
declare COPY_TO_MOUNT="${PRIS_DIR}/copy-to-mount"
declare MOUNT="/mnt/lfs"
declare RESTART_CNT="${PRIS_DIR}/restart-count"
declare LFS_HOME='/home/lfs'

# Pkg vars which get set every time download_pkg() is called.
declare PKG_FILE=
declare PKG_WORKDIR=

# Pkg vars which get set every time download_pkg() is called.
declare -a PATCH_FILES=()

##
# Setup network client to communicate with outside world.
#
function open_io {
    open_data_io
    open_sgnl_io
}

function open_data_io {
    while ! eval "exec ${DATA_IO}<> ${DATA_IO_PORT}" ; do
        echo "====== DATA_IO_PORT not listening ======" >> ${PRIS_LOG}
        sleep 5
    done
}

function open_sgnl_io {
    while ! eval "exec ${SGNL_IO}<> ${SGNL_IO_PORT}" ; do
        echo "====== SGNL_IO_PORT not listening ======" >> ${PRIS_LOG}
        sleep 5
    done
}

function echo_cmd {
    sleep 1
    PROMPT='>'
    printf "[pris:$PWD]\n$PROMPT $1\n" | tee -a ${PRIS_LOG}
}

function eval_cmd {
#     # Eval cmd; if any redirection, treat a bit differently
#     if [[ $1 = *@(>|EOF)* ]] ; then
#         eval "$1
# 1>>${PRIS_LOG} 2>&1"
#     else
    #     eval "$1 1>>${PRIS_LOG} 2>&1"
    # fi
    eval "$1 2>&1" | tee -a ${PRIS_LOG}
}

function cmd {
    echo_cmd "$@"
    eval_cmd "$@"
}

function do_init_script_cmd {
    echo_cmd "$@"
    local OUT=`$1`
    if [[ $OUT = *OK* ]] ; then
        declare MSG=${OUT%OK*}
        declare -i LEN=${#MSG}
        LEN=$LEN-31
        MSG=${MSG:0:LEN}
        declare -i P=79-$LEN
        printf "%s%${P}s\n" "$MSG" "[  OK  ]" >> "${PRIS_LOG}"
    fi
    # TODO Deal with other case
}

##
# Sets global var $PKG_FILE
#
function get_pkg_file {
    # Split pkg path into filename and directory.
    DIR=${1%/*}
    N=${#DIR}
    N=$N+1
    PKG_FILE=${1:N}
    # Strip any extra cgi arguments
    PKG_FILE=${PKG_FILE%%\?*}
}

##
# Sets global var $PKG_WORKDIR
#
function get_pkg_workdir {
    PKG_WORKDIR=`tar tf $1 | head -n 1`
    # Strip initial './', if any
    PKG_WORKDIR=${PKG_WORKDIR#./}
    # Strip everything beyond first dir.
    PKG_WORKDIR=${PKG_WORKDIR%%/*}
}

##
# Sets global array $PATCH_FILES
#
function get_patch_files {
    declare -i I=0
    while test ${#*} -gt 0 ; do
        DIR=${1%/*}
        N=${#DIR}
        N=$N+1
        PATCH_FILE=${1:N}
        PATCH_FILES[$I]=${PATCH_FILE}
        I=$I+1
        shift
    done
}

##
# Download a pkg file, falling back to a safe source if necessary.
# Also sets global var $PKG_FILE.
#
function download_pkg {
    get_pkg_file $1
    [[ -e ${PKG_FILE} ]] && rm -rf ${PKG_FILE}
    CMD="wget $1"
    cmd "${CMD}"
    if ! test -f ${PKG_FILE} ; then
        CMD="wget $FALLBACK_DIR/${PKG_FILE}"
        cmd "${CMD}"
    fi
    if ! test -f ${PKG_FILE} ; then
        return -1
    fi
    return 0
}

##
# Same as download_pkg() above, but with a different fallback.
# Also sets global var $PKG_FILE.
#
function download_blfs_pkg {
    get_pkg_file $1
    [[ -e ${PKG_FILE} ]] && rm -rf ${PKG_FILE}
    CMD="wget $1"
    cmd "${CMD}"
    if ! test -f ${PKG_FILE} ; then
        LETTER=${PKG_FILE:0:1}
        LETTER=$(echo $LETTER | tr '[:upper:]' '[:lower:]')
        CMD="wget $BLFS_FALLBACK_DIR/$LETTER/${PKG_FILE}"
        cmd "${CMD}"
    fi
    if ! test -f ${PKG_FILE} ; then
        return -1
    fi
    return 0
}

##
# Downloads an xorg pkg list, then downloads each item in list, 
# then md5 verifies.
# 
function install_xorg_list {
    # Save current PKG_FILE
    SV_PKG_FILE=${PKG_FILE}
    get_pkg_file $2
    LIST_FILE=${PKG_FILE}
    PKG_FILE=${SV_PKG_FILE}
    [[ -e ${LIST_FILE} ]] && rm -rf ${LIST_FILE}
    cmd "wget $2"
    if ! test -f ${LIST_FILE} ; then
        return -1
    fi
    MD5_FILE=${2%.*}
    MD5_FILE="${MD5_FILE}.md5"
    cmd "wget ${MD5_FILE}"
    cmd "mkdir $1"
    cmd "cd $1"
    cmd "grep -v '^#' ../${LIST_FILE} | wget -i- -c \\
    -B http://xorg.freedesktop.org/releases/individual/$1/"
    MD5_FILE=${MD5_FILE##*/}
    cmd "md5sum -c ../${MD5_FILE}"

    # Comment out unneeded drivers
    if [[ $1 = driver ]] ; then
        cmd "sed -i -e \"s/^xf86/#xf86/\" \\
    -e \"s/#xf86-input-keyboard/xf86-input-keyboard/\" \\
    -e \"s/#xf86-input-mouse/xf86-input-mouse/\" \\
    -e \"s/#xf86-video-chips/xf86-video-chips/\" \\
    ../${LIST_FILE}"
    fi

    for ITEM in $(grep -v '^#' ../${LIST_FILE}) ; do
        ITEMDIR=$(echo $ITEM | sed 's/.tar.bz2//')
        cmd "tar -xvf $ITEM"
        cmd "cd $ITEMDIR"
        # Patches for special cases.
        case $(basename "$PWD") in
        libX11-1.1.2 )
            PATCH_FILE=$(basename "$XORG_LIBX11_PATCH0")
            cmd "patch -Np1 -i ../../${PATCH_FILE}"
            cmd "sed -i 's/_XGet/XGet/' modules/im/ximcp/imDefLkup.c"
            ;;
        libXfont-1.2.8 )
            PATCH_FILE=$(basename "$XORG_LIBXFONT_PATCH0")
            cmd "patch -Np1 -i ../../${PATCH_FILE}"
            cmd "sed -i 's/(ft_isdigit/(isdigit/' src/FreeType/fttools.c"
            ;;
        esac
        if [[ $1 != driver ]] ; then
            cmd './configure $XORG_CONFIG'
        else
            cmd './configure $XORG_CONFIG \
    --with-xorg-module-dir=$XORG_PREFIX/lib/X11/modules'
        fi
        if [[ $1 != proto ]] ; then
            cmd 'make'
        fi
        cmd 'make install'
        if [[ $1 = lib ]] ; then
            cmd 'ldconfig'
        fi
        cmd 'cd ..'
        cmd "rm -rf $ITEMDIR"
    done
    cmd 'cd ..'
    return 0
}

##
# Another download fn, for perl modules.
# Also sets global var $PKG_FILE.
#
function download_perl_mod {
    get_pkg_file $1
    [[ -e ${PKG_FILE} ]] && rm -rf ${PKG_FILE}
    CMD="wget $1"
    cmd "${CMD}"
    if ! test -f ${PKG_FILE} ; then
        CMD="wget $PERLMOD_FALLBACK_DIR/${PKG_FILE}"
        cmd "${CMD}"
    fi
    if ! test -f ${PKG_FILE} ; then
        return -1
    fi
    return 0
}

##
# Unpacks a pkg.
# Also sets global vars $PKG_FILE and $PKG_WORKDIR.
#
function unpack_pkg {
    get_pkg_file $1
    get_pkg_workdir ${PKG_FILE}
    [[ -e ${PKG_WORKDIR} ]] && rm -rf ${PKG_WORKDIR}
    cmd "tar xvf ${PKG_FILE}"
}

##
# Download patch files, already assumed to be at safe locations.
# Sets global array $PATCH_FILES to list of filenames.
#
function download_patches {
    declare -i I=0
    while test ${#*} -gt 0 ; do
        DIR=${1%/*}
        N=${#DIR}
        N=$N+1
        PATCH_FILE=${1:N}
        [[ -e ${PATCH_FILE} ]] && rm -rf ${PATCH_FILE}
        CMD="wget $1"
        cmd "${CMD}"
        PATCH_FILES[$I]=${PATCH_FILE}
        I=$I+1
        shift
    done
}

##
##
# Same as download_pkg() above, but with a different fallback.
# Also sets global array $PATCH_FILES[].
#
function download_blfs_patches {
    declare -i I=0
    while test ${#*} -gt 0 ; do
        DIR=${1%/*}
        N=${#DIR}
        N=$N+1
        PATCH_FILE=${1:N}
        [[ -e ${PATCH_FILE} ]] && rm -rf ${PATCH_FILE}
        CMD="wget $1"
        cmd "${CMD}"
        if ! test -f ${PATCH_FILE} ; then
            LETTER=${PATCH_FILE:0:1}
            CMD="wget $BLFS_FALLBACK_DIR/$LETTER/${PATCH_FILE}"
            cmd "${CMD}"
        fi
        PATCH_FILES[$I]=${PATCH_FILE}
        I=$I+1
        shift
    done
}

##
# Looks for marker within the ${PRIS_MARKER_DIR}.
# Returns 0 | 1.
#
function marker_exists {
    if test ! -f "${PRIS_MARKER_DIR}/$1" ; then
        return 1
    fi
    return 0
}

##
# Places a marker in the ${PRIS_MARKER_DIR}.
#
function place_marker {
    touch "${PRIS_MARKER_DIR}/$1"
}

##
# Standard install procedure for perl modules
function install_perl_mod {
    download_perl_mod $1
    unpack_pkg $1
    cmd "cd ${PKG_WORKDIR}"
    cmd "perl Makefile.PL"
    cmd "make"
    cmd "make test"
    cmd "make install"
    cmd "cd .."
    cmd "rm -rf ${PKG_WORKDIR}"
}

function incr_restart_cnt {
    if ! test -f $RESTART_CNT ; then
        echo 0 > $RESTART_CNT
        return
    fi
    CNT=`cat $RESTART_CNT`
    let "CNT++"
    echo $CNT > $RESTART_CNT
    # Also place a marker.
    place_marker "restart${CNT}"
}

##
# Celebrate
#
function victory_dance {
    for (( COUNT=0; COUNT<60; COUNT++ )) ; do
        sleep 1
#        printf "COMPILATION COMPLETE\n" | tee --append ${PRIS_LOG} >&${DATA_IO}
        printf "COMPILATION COMPLETE\n" >> ${PRIS_LOG}
    done
}

function write_pid {
    echo $$ > "${PRIS_DIR}/$1.pid"
}

function remove_pid {
    rm "${PRIS_DIR}/$1.pid"
}
