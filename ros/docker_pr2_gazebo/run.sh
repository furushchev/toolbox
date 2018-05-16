#!/bin/bash
docker build -t furushchev/pr2eus_tutorials .
docker run --name test --rm -e ROS_DISPLAY -e QT_X11_NO_MITSHM=1 -v /tmp/.X11-unix:/tmp/.X11-unix:rw --net=host pr2eus_tutorials rosrun pr2eus_tutorials pr2_tabletop_sim.sh  run_rviz:=false --screen
