#!/bin/bash

set -e

export QT_X11_NO_MITSHM=1

source /ros/kinetic/devel/setup.bash
# xvfb-run -s "-screen 0 640x480x24"
exec  "$@"
