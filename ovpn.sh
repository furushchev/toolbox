#!/bin/bash

set -e

OVPN_DATA="ovpn-data"
VPN_HOSTNAME=$(hostname)

read -p "vpn credential file name? [client]: " CLIENTNAME
read -p "vpn port? [1194]: " VPN_PORT
read -p "vpn protocol? [udp]: " VPN_PROTOCOL

CLIENTNAME=${CLIENTNAME:-client}
if [ "$CLIENTNAME" = "VPN_HOSTNAME" ]; then
  echo "Credential file name must be different from vpn server name ($VPN_HOSTNAME)"
  exit 1
fi

VPN_PORT=${VPN_PORT:-1194}
VPN_PROTOCOL=${VPN_PROTOCOL:-"udp"}

if [ "$VPN_PROTOCOL" != "tcp" ] && [ "$VPN_PROTOCOL" != "udp" ]; then
  echo "Protocol must be 'tcp' or 'udp' ($VPN_PROTOCOL)"
  exit 1
fi

echo "Now creating VPN settings."

CONFIRM=n
while [ "$CONFIRM" != "y" ]; do
  echo '*****************************'
  echo " Data Volume Container: $OVPN_DATA"
  echo " Credential File Name: $CLIENTNAME.ovpn"
  echo " VPN Port: $VPN_PORT/$VPN_PROTOCOL"
  echo " NOTE:"
  echo "   If you asked password, please type onetime password as you like."
  echo "   If you asked CA name, please type hostname. your hostname is ${VPN_HOSTNAME}"
  echo '*****************************'
  read -p "Do you agree and understand? [y/n]: " CONFIRM
done
echo "OK! Go ahead!"


error(){
  docker rm -f "${OVPN_DATA}"
  trap - ERR
  exit 1
}

docker run --name ${OVPN_DATA} -v /etc/openvpn busybox
trap error ERR
docker run --volumes-from ${OVPN_DATA} --rm kylemanna/openvpn ovpn_genconfig -u ${VPN_PROTOCOL}://${VPN_HOSTNAME}:${VPN_PORT}
docker run --volumes-from ${OVPN_DATA} --rm -it kylemanna/openvpn ovpn_initpki
docker run --volumes-from ${OVPN_DATA} -d -p ${VPN_PORT}:1194/${VPN_PROTOCOL} --cap-add=NET_ADMIN kylemanna/openvpn
docker run --volumes-from ${OVPN_DATA} --rm -it kylemanna/openvpn easyrsa build-client-full ${CLIENTNAME} nopass
docker run --volumes-from ${OVPN_DATA} --rm kylemanna/openvpn ovpn_getclient ${CLIENTNAME} > ${CLIENTNAME}.ovpn

echo "***   Setup finished successfully!   ***"
CONFIRM=n
while [ "$CONFIRM" != "y" ]; do
  read -p "Do you want to register to startup application? [y/n]: " CONFIRM
  if [ "$CONFIRM" = "n" ]; then
    exit 0
  fi
done

sudo cat > /etc/init/docker-openvpn.conf <<EOF
# script for running docker based openvpn server

description "Running docker based openvpn server"
author "Yuki Furuta <furushchev@jsk.imi.i.u-tokyo.ac.jp>"

start on (starting network-interface
          or starting network-manager
          or starting networking) and started docker
stop on runlevel [!2345]

respawn

script
  exec docker run --volumes-from ${OVPN_DATA} -d -p ${VPN_PORT}:1194/${VPN_PROTOCOL} --cap-add=NET_ADMIN kylemanna/openvpn
end script
EOF

echo "Registered startup script to /etc/init/docker-openvpn.conf"
