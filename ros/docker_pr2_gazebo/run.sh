#!/bin/bash

xhost +local:root

docker run \
    --name test \
    --rm \
    --net=host \
    furushchev/pr2eus_tutorials:latest \
    rosrun pr2eus_tutorials pr2_tabletop_sim.sh gui:=false run_rviz:=false --screen
#    roslaunch pr2_gazebo pr2_empty_world.launch KINECT1:=true gui:=false paused:=false

xhost -local:root
