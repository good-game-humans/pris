#!/bin/bash

source "/pris/pris-fns.sh"

##############################################################################
## INIT                                                                     ##

open_data_io

##############################################################################
## MAIN                                                                     ##

# Kill existing tail
kill `ps -C 'tail -n 1 -F ${PRIS_LOG}' -o pid=`
eval "/usr/bin/tail -n 1 -F ${PRIS_LOG} >&${DATA_IO} &"
exit 0
