FROM osrf/ros:kinetic-desktop-full
MAINTAINER Yuki Furuta <furushchev@jsk.imi.i.u-tokyo.ac.jp>

RUN sed -i 's@packages.ros.org/ros@packages.ros.org/ros-shadow-fixed@g' /etc/apt/sources.list.d/ros-latest.list

RUN apt-get update && apt-get install -y -yy -q \
    xvfb \
    python-catkin-tools \
    python-wstool \
    ros-kinetic-eusurdf \
    ros-kinetic-jsk-interactive-marker \
    ros-kinetic-pr2-gazebo \
    ros-kinetic-pr2eus-tutorials \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /ros/kinetic/src
RUN cd /ros/kinetic/src && wstool init && wstool set jsk-ros-pkg/jsk_pr2eus --git https://github.com/furushchev/jsk_pr2eus.git -v pr2eus-tabletop-test-sample -u -y
RUN cd /ros/kinetic && . /opt/ros/kinetic/setup.sh && catkin init && catkin build pr2eus_tutorials

COPY .gazebo /root/.gazebo
COPY ./ros_entrypoint.sh /
ENTRYPOINT ["/ros_entrypoint.sh"]
CMD ["bash"]
