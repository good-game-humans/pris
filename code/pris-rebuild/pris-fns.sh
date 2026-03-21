PRIS_DIR="/pris"
PRIS_LOG="${PRIS_DIR}/pris.log"
PRIS_MARKER_DIR="${PRIS_DIR}/markers"
PROMPT='\033[31m>\033[0m'
LFS_HOME='/home/lfs'

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

function echo_prompt {
    # Terminate with a newline even though the desired display on pris-screen 
    printf "$PROMPT_PREPEND[pris:$PWD]$PROMPT \n"
}

##
# Echoes a command to output
#
function echo_cmd {
    echo_prompt
    sleep 1
    printf '%s\n' "$1"
}

function eval_cmd {
    # Eval cmd; if any redirection, treat a bit differently
    if [[ $1 = *@(>|EOF)* ]] ; then
        eval "$1
 2>&1"
    else
        eval "$1 2>&1"
    fi
}

function cmd {
    echo_cmd "$@"
    eval_cmd "$@"
}

