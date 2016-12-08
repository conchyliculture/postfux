#!/bin/bash

JAILNAME="postfux-jail"
PIDFILE="postfux-jail.pid"

check_running() {
    if [ -f $PIDFILE ] ;  then
        PID=$(cat $PIDFILE)

        firejail --list | grep "${PID}.*${JAILNAME}" > /dev/null
        if [ $? -eq 1 ]; then
            # Not running
            rm $PIDFILE
            return 0
        else
            echo "postfux firejail already running ($PID)"
            return 1
        fi
    fi

    return 0
}

check_running
if [ $? -eq 0 ]; then
    echo -n "starting postfux firejail"
    firejail --private \
        --quiet \
        --noprofile \
        --private-dev \
        --nosound \
        --no3d \
        --seccomp \
        --caps.drop=all \
        --name=${JAILNAME} \
        -- \
        ruby server.rb &
    PID=$!
    echo -n $PID >> ${PIDFILE}
    echo "$PID ."
fi
