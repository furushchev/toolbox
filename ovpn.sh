#!/bin/bash

set -e

read -p "client name? [client]: " CLIENTNAME
read -p "vpn port? [443]: " VPN_PORT
export OVPN_DATA="ovpn-data"
export VPN_HOSTNAME=${HOSTNAME}
export CLIENTNAME=${CLIENTNAME:-"client"}
export VPN_PORT=${VPN_PORT:-443}

error(){
  docker rm "${OVPN_DATA}"
  trap - ERR
  exit 1
}

echo "Nor creating VPN settings."
echo '*****************************'
echo "If you asked password, please type onetime password as you like."
echo "If you asked CA name, please type hostname. your hostname is ${VPN_HOSTNAME}"
echo '*****************************'

docker run --name ${OVPN_DATA} -v /etc/openvpn busybox
trap error ERR
docker run --volumes-from ${OVPN_DATA} --rm kylemanna/openvpn ovpn_genconfig -u tcp://${VPN_HOSTNAME}:${VPN_PORT}
docker run --volumes-from ${OVPN_DATA} --rm -it kylemanna/openvpn ovpn_initpki
docker run --volumes-from ${OVPN_DATA} -d -p ${VPN_PORT}:1194/tcp --cap-add=NET_ADMIN kylemanna/openvpn
docker run --volumes-from ${OVPN_DATA} --rm -it kylemanna/openvpn easyrsa build-client-full ${CLIENTNAME} nopass
docker run --volumes-from ${OVPN_DATA} --rm kylemanna/openvpn ovpn_getclient ${CLIENTNAME} > ${CLIENTNAME}.ovpn
