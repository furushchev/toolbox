#!/bin/bash

xhost +local:root

docker run \
    --name test \
    --rm \
    --net=host \
    --env="DISPLAY" \
    --volume="/tmp/.X11-unix:/tmp/.X11-unix:rw" \
    furushchev/pr2eus_tutorials:latest \
    rqt
#    roslaunch pr2_gazebo pr2_empty_world.launch KINECT1:=true gui:=false paused:=false
#    rosrun pr2eus_tutorials pr2_tabletop_sim.sh gui:=false run_rviz:=false --screen

#    -e QT_X11_NO_MITSHM=1 \

xhost -local:root
