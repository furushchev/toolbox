#!/usr/bin/env bash

panic() {
  echo "Error: $1"
  exit 1
}

yes-or-no() {
    local Answer
    while true; do
        read -p "$@ [Y/n]" Answer
        case $Answer in
            [Yy]* )
                (echo "Yes")
                return 0
                break
                ;;
            '' | [Nn]* )
                (echo "No")
                return 1
                break
                ;;
            * )
                echo Please answer Yes or No.
        esac
    done
}

# OS CHECK
if [ -e /etc/lsb-release ]; then
    if [ "`lsb_release -is`" != "Ubuntu" ]; then
        panic "Only Ubuntu is supported"
    fi
else
    panic "Only Ubuntu is supported"
fi

# ARGS CHECK
if [ $# -ne 2 ]; then
    panic "gsync.sh local_path remote_path"
fi

JSYNC=/opt/jdrivesync/jdrivesync.sh

if [ ! -e $JSYNC ]; then
  echo "jdrivesync is not found. installing..."
  wget https://github.com/siom79/jdrivesync/releases/download/jdrivesync-0.3.0/jdrivesync_0.3.0_all.deb -q -O /tmp/jdrivesync.deb
  sudo dpkg -i /tmp/jdrivesync.deb
fi
RUN_CMD="$JSYNC --no-delete --html-report -c -u -l $1 -r $2"
echo "Running \"$RUN_CMD\""
if yes-or-no "ok?"; then
    exec $RUN_CMD
else
    panic "Aborted"
fi










