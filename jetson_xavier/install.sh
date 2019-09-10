#!/bin/bash

sudo apt-get update -y -q -qq
sudo apt-get install -y -q -qq git unionfs-fuse


git clone https://github.com/furushchev/toolbox.git /tmp/toolbox

cd /tmp/toolbox/jetson_xavier
sudo install -m 0644 60-kernel.conf /etc/sysctl.d/60-kernel.conf
sudo install -m 0755 unionfs-init /usr/sbin/unionfs-init
sudo mv /sbin/init /sbin/init.bak
sudo install -m 0755 switch_init /usr/sbin/switch_init
sudo switch_init
